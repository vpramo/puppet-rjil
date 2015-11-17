class rjil::commonservices::jenkins::cloudenvs (
  $envs = {
  }
) {
  create_resources(rjil::commonservices::jenkins::cloudenv, $envs)
}
