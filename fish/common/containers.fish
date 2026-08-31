# function infer --description "launche facebook infer static analyzer as container"
#     command $CTRT run --rm -it -v (pwd):/(pwd):Z -w (pwd) localhost/infer:latest $argv
# end


# function aider --description "run aider assistant in current directory"
#     command $CTRT run --rm -it \
#         -v (pwd):/(pwd) -w (pwd) \
#         paulgauthier/aider-full $argv
# end

# function threagile --description "run threagile threat modeling tool"
#     # first attempt to identify a project root.
#     set -l voldir (pwd)
#     if not test -e "$voldir/.git"
#         for check in "../.git" "../../.git"
#             if test -e "$voldir/$check"
#                 set voldir (realpath "$voldir/$check")
#             end
#         end
#     end
#     echo "TODO: find a working docker container (likely build it yourself...)"
#     command $CTRT run --rm -it \
#         -v "$voldir:/$voldir" -w (pwd) \
#         threagile/threagile $argv
# end
