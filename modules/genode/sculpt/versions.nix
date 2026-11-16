## Sculpt OS releases: data only.
##
## Download page: https://genode.org/download/sculpt
## Signatures are detached and follow the `<img>.asc` scheme; they are
## verified in ./verify.nix against the key pinned in ./pubkey.asc.
{
  "26.04" = {
    imgUrl = "https://genode.org/files/sculpt/sculpt-26-04.img";
    imgSha256 = "241b916ab9e3ed25a089c27119aac98f80fe4d3e67101936b4e69d7f1c708f14";
    sigSha256 = "48a3b9e9dba24c043bdced3f748602d62bd8fd9c37089c523fa39c27393d2396";
  };

  "26.10" = {
    imgUrl = "https://genode.org/files/sculpt/sculpt-26-10.img";
    imgSha256 = "fc516fe436ec0d926cebb4a4b4dc9d5f5bc7e50cc4eabc8e54c01a8fb1820955";
    sigSha256 = "5273eaebb1c63bfb4a3116878bc372954c9e612d7d69824817767c8ad15f9a7c";
  };
}
