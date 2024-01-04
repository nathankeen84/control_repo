# @summary Generates and deploys the default CoreDNS DNS provider for Kubernetes
#
# @param cluster_cidr The internal cluster CIDR to proxy for
# @param cni_registry The Flannel CNI plugin image registry to use
# @param cni_image The Flannel CNI plugin image name to use
# @param cni_image_tag The Flannel CNI plugin image tag to use
# @param registry The Flannel image registry to use
# @param image The Flannel image name to use
# @param image_tag The Flannel image tag to use
# @param daemonset_config Additional configuration to merge into the DaemonSet object
# @param net_config Additional configuration to merge into net-conf.json for Flannel
# @param image_pull_secrets the secrets to pull from private registries
#
class k8s::server::resources::flannel (
  K8s::Ensure $ensure                 = $k8s::ensure,
  Stdlib::Unixpath $kubeconfig        = $k8s::server::resources::kubeconfig,
  K8s::CIDR $cluster_cidr             = $k8s::server::resources::cluster_cidr,
  String[1] $cni_registry             = $k8s::server::resources::flannel_cni_registry,
  String[1] $cni_image                = $k8s::server::resources::flannel_cni_image,
  String[1] $cni_image_tag            = $k8s::server::resources::flannel_cni_tag,
  String[1] $registry                 = $k8s::server::resources::flannel_registry,
  String[1] $image                    = $k8s::server::resources::flannel_image,
  String[1] $image_tag                = $k8s::server::resources::flannel_tag,
  Hash[String,Data] $daemonset_config = $k8s::server::resources::flannel_daemonset_config,
  Optional[Array] $image_pull_secrets = $k8s::server::resources::image_pull_secrets,
  Hash[String,Data] $net_config       = {},
) {
  assert_private()

  $_cluster_cidr_v4 = flatten($cluster_cidr).filter |$cidr| { $cidr =~ Stdlib::IP::Address::V4::CIDR }
  $_cluster_cidr_v6 = flatten($cluster_cidr).filter |$cidr| { $cidr =~ Stdlib::IP::Address::V6::CIDR }

  $_net_conf = delete_undef_values(
    {
      'Network'     => $_cluster_cidr_v4[0],
      'IPv6Network' => $_cluster_cidr_v6[0],
      'EnableIPv4'  => !$_cluster_cidr_v4.empty(),
      'EnableIPv6'  => !$_cluster_cidr_v6.empty(),
      'Backend'     => {
        'Type' => 'vxlan',
      },
    } + $net_config
  )

  kubectl_apply {
    default:
      ensure        => $ensure,
      kubeconfig    => $kubeconfig,
      provider      => 'kubectl',
      namespace     => 'kube-system',
      resource_name => 'flannel';

    'flannel ClusterRole':
      api_version => 'rbac.authorization.k8s.io/v1',
      kind        => 'ClusterRole',
      content     => {
        metadata => {
          labels => {
            'kubernetes.io/managed-by' => 'puppet',
          },
        },
        rules    => [
          {
            apiGroups     => ['extensions'],
            resources     => ['podsecuritypolicies'],
            verbs         => ['use'],
            resourceNames => ['psp.flannel.unprivileged'],
          },
          {
            apiGroups => [''],
            resources => ['pods'],
            verbs     => ['get'],
          },
          {
            apiGroups => [''],
            resources => ['nodes'],
            verbs     => ['list','watch'],
          },
          {
            apiGroups => [''],
            resources => ['nodes/status'],
            verbs     => ['patch'],
          },
        ],
      };

    'flannel ClusterRoleBinding':
      api_version => 'rbac.authorization.k8s.io/v1',
      kind        => 'ClusterRoleBinding',
      content     => {
        metadata => {
          labels => {
            'kubernetes.io/managed-by' => 'puppet',
          },
        },
        subjects => [
          {
            kind      => 'ServiceAccount',
            name      => 'flannel',
            namespace => 'kube-system',
          },
        ],
        roleRef  => {
          kind     => 'ClusterRole',
          name     => 'flannel',
          apiGroup => 'rbac.authorization.k8s.io',
        },
      };

    'flannel ServiceAccount':
      api_version => 'v1',
      kind        => 'ServiceAccount',
      content     => {
        metadata => {
          labels => {
            'kubernetes.io/managed-by' => 'puppet',
          },
        },
      };

    'flannel ConfigMap':
      api_version => 'v1',
      kind        => 'ConfigMap',
      content     => {
        metadata => {
          labels => {
            tier                       => 'node',
            'k8s-app'                  => 'flannel',
            'kubernetes.io/managed-by' => 'puppet',
          },
        },
        data     => {
          'cni-conf.json' => to_json({
              name       => 'cbr0',
              cniVersion => '0.3.1',
              plugins    => [
                {
                  type     => 'flannel',
                  delegate => {
                    hairpinMode      => true,
                    isDefaultGateway => true,
                  },
                },
                {
                  type         => 'portmap',
                  capabilities => {
                    portMappings => true,
                  },
                },
              ],
          }),
          'net-conf.json' => $_net_conf.to_json(),
        },
      };

    'flannel DaemonSet':
      api_version => 'apps/v1',
      kind        => 'DaemonSet',
      recreate    => true,
      content     => {
        metadata => {
          labels => {
            'tier'                     => 'node',
            'k8s-app'                  => 'flannel',
            'kubernetes.io/managed-by' => 'puppet',
          },
        },
        spec     => {
          selector       => {
            matchLabels => {
              'tier'                     => 'node',
              'k8s-app'                  => 'flannel',
              'kubernetes.io/managed-by' => 'puppet',
            },
          },
          template       => {
            metadata => {
              labels => {
                'tier'                     => 'node',
                'k8s-app'                  => 'flannel',
                'kubernetes.io/managed-by' => 'puppet',
              },
            },
            spec     => {
              hostNetwork        => true,
              priorityClassName  => 'system-node-critical',
              serviceAccountName => 'flannel',
              tolerations        => [
                {
                  effect   => 'NoSchedule',
                  operator => 'Exists',
                },
                {
                  effect   => 'NoExecute',
                  operator => 'Exists',
                },
              ],
              nodeSelector       => {
                'kubernetes.io/os' => 'linux',
              },
              containers         => [
                {
                  name            => 'flannel',
                  image           => "${registry}/${image}:${image_tag}",
                  command         => ['/opt/bin/flanneld'],
                  args            => ['--ip-masq', '--kube-subnet-mgr'],
                  resources       => {
                    requests => {
                      cpu    => '100m',
                      memory => '50Mi',
                    },
                    limits   => {
                      cpu    => '100m',
                      memory => '50Mi',
                    },
                  },
                  securityContext => {
                    privileged   => false,
                    capabilities => {
                      add => ['NET_ADMIN', 'NET_RAW'],
                    },
                  },
                  env             => [
                    {
                      name      => 'POD_NAME',
                      valueFrom => {
                        fieldRef => {
                          fieldPath => 'metadata.name',
                        },
                      },
                    },
                    {
                      name      => 'POD_NAMESPACE',
                      valueFrom => {
                        fieldRef => {
                          fieldPath => 'metadata.namespace',
                        },
                      },
                    },
                  ],
                  volumeMounts    => [
                    {
                      name      => 'run',
                      mountPath => '/run/flannel',
                    },
                    {
                      name      => 'flannel-cfg',
                      mountPath => '/etc/kube-flannel/',
                    },
                  ],
                },
              ],
              imagePullSecrets   => $image_pull_secrets,
              initContainers     => [
                {
                  name         => 'install-cni-plugin',
                  image        => "${cni_registry}/${cni_image}:${cni_image_tag}",
                  command      => ['cp'],
                  args         => [
                    '-f',
                    '/flannel',
                    '/opt/cni/bin/flannel',
                  ],
                  volumeMounts => [
                    {
                      name      => 'host-cni-bin',
                      mountPath => '/opt/cni/bin',
                    },
                  ],
                },
                {
                  name         => 'install-cni',
                  image        => "${cni_registry}/${cni_image}:${cni_image_tag}",
                  command      => ['cp'],
                  args         => [
                    '-f',
                    '/etc/kube-flannel/cni-conf.json',
                    '/etc/cni/net.d/10-flannel.conflist',
                  ],
                  volumeMounts => [
                    {
                      name      => 'cni',
                      mountPath => '/etc/cni/net.d',
                    },
                    {
                      name      => 'flannel-cfg',
                      mountPath => '/etc/kube-flannel',
                    },
                  ],
                },
              ],
              volumes            => [
                {
                  name     => 'run',
                  hostPath => {
                    path => '/run/flannel',
                    type => 'DirectoryOrCreate',
                  },
                },
                {
                  name     => 'cni',
                  hostPath => {
                    path => '/etc/cni/net.d',
                  },
                },
                {
                  name      => 'flannel-cfg',
                  configMap => {
                    name => 'flannel',
                  },
                },
                {
                  name     => 'host-cni-bin',
                  hostPath => {
                    path => '/opt/cni/bin',
                  },
                },
              ],
            },
          },
          updateStrategy => {
            rollingUpdate => {
              maxUnavailable => 1,
            },
            type          => 'RollingUpdate',
          },
        },
      } + $daemonset_config;
  }
}
