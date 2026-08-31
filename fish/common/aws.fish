# shell helper functions for working with aws cli

function aws-region
   if test -z "$argv[1]"
        echo "missing region name"
   else
        set -gx AWS_DEFAULT_REGION "$argv[1]"
   end
end

function aws-profile
	   if test -z "$argv[1]"
			   echo "missing profile name"
	   else
			   set -gx AWS_DEFAULT_PROFILE "$argv[1]"
			   set -gx AWS_PROFILE "$argv[1]"
       end
end

function aws-profile-sso
    if test -z "$argv[1]"
        echo "missing profile name: $argv"
        return 1
    end

    set -gx AWS_DEFAULT_PROFILE "$argv[1]"
    set -gx AWS_PROFILE "$argv[1]"

    echo "Checking login state"
    set -l identity (aws sts get-caller-identity) 2>/dev/null
    if test -z "$identity"
        echo "No Active Session login required"
        aws sso login
    else
        set -l sso_account (echo "$identity" | jq -r .Account)
        set -l session_account (aws configure get sso_account_id --profile "$argv[1]")
        if test "$sso_account" != "$session_account"
            echo "login required due to Account mismatch."
            aws sso login
        end
    end

    set identity (aws sts get-caller-identity)
    if test -z "$identity"
        echo "login failed"
        return 1
    end
    echo "Logged in as:"
    echo "$identity" | jq .
end


function aws-token-sso
    if not aws-profile-sso "$argv[1]"
        return 1
    end

    for filename in (ls -t ~/.aws/sso/cache/*.json)
        set -l sso_access_token (jq <"$filename" -r '.accessToken')

        if test $sso_access_token != "null"
            set -l default_region (aws configure get default.region)
            set -l profile_region (aws configure get "$argv[1]".region)
            set -l region "$default_region"
            if test -z "$profile_region"
                set region 
            end
            
            set -l account_id (aws configure get "$argv[1]".sso_account_id)
            set -l role_name (aws configure get "$argv[1]".sso_role_name)

            set -l sso_access_token (jq <"$filename" -r '.accessToken')
            set -l result (aws sso get-role-credentials --profile "$argv[1]" --region "$region" --role-name "$role_name" --account-id "$account_id" --access-token "$sso_access_token")
            set -l access_id (echo "$result" | jq -r '.roleCredentials.accessKeyId')
            set access_key (echo "$result" | jq -r '.roleCredentials.secretAccessKey')
            set session_access_token (echo "$result" | jq -r '.roleCredentials.sessionToken')

            if test "$access_id" != "null"; and test "$access_key" != "null"; and test "$session_access_token" != "null"
                set -gx AWS_ACCESS_KEY_ID $access_id
                set -gx AWS_SECRET_ACCESS_KEY $access_key
                set -gx AWS_SESSION_TOKEN $session_access_token
                return 0
            else
                echo "Could not fetch token: $result"
                return 1
            end
        end 
    end
    echo "No valid token found"
    return 1
end

function aws-token
	aws-reset-token

	set -l result (aws sts assume-role --role-arn (aws configure get role_arn) --role-session-name "dev-token")

	set -x AWS_ACCESS_KEY_ID (echo $result | jq -r '.Credentials.AccessKeyId')
	set -x AWS_SECRET_ACCESS_KEY (echo $result | jq -r '.Credentials.SecretAccessKey')
	set -x AWS_SESSION_TOKEN (echo $result | jq -r '.Credentials.SessionToken')
end



function aws-reset-token
	set -x AWS_ACCESS_KEY_ID
	set -x AWS_SECRET_ACCESS_KEY
	set -x AWS_SESSION_TOKEN
end


# function ec2ssh
#     eval "ssh -o ForwardAgent=yes "(aws ec2 describe-instances | jq -r '.Reservations[].Instances[] | (.NetworkInterfaces[0].PrivateIpAddress)+"\t# "+(.Tags[0].Value)' | fzf)
# end
#
# function ec2mosh
#     eval "mosh "(aws ec2 describe-instances | jq -r '.Reservations[].Instances[] | (.NetworkInterfaces[0].PrivateIpAddress)+"\t# "+(.Tags[0].Value)' | fzf)
# end
#
