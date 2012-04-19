#!/bin/sh
# <oldrev> <newrev> <refname>
# Upload diff beetwen revisions to Reviewboard

#colors
c_red="\E[0;31m"
c_std="\E[0;39m"
c_green="\E[0;32m"

while read oldrev newrev ref
do
    echo -e "${c_green}Start working with ReviewBoard${c_std}"

    #getting project name
	projectName=`git config reviewboard.projectName`
	if [ "$projectName" == '' ]
	then
		echo -e "${c_red}Project name wasn't found. Review request will not be send.${c_std}"
		exit 0
	fi
	
	username=`git config reviewboard.username`
	password=`git config reviewboard.password`

	if [ "$username" == '' ] || [ "$password" == '' ]
    then 
		echo -e "${c_red}Username and\or password to reviewboard wasn't found.${c_std}"
		exit 0;
    fi


	#getting project group
    group=`git config reviewboard.group`
    if [ $group !== "" ]
	then 
		group='all'
    fi


    echo -e "${c_green}Prepearing review request to $projectName project${c_std}"
    #creating patch
    fileDiff="/var/diff/$projectName.path"
    git diff-tree -p $older $newrev > $fileDiff
	chmod 777 $fileDiff
	
	#getting messages from commits
    msg=`git shortlog $oldrev..$newrev`
    
    if (echo $msg | grep '#rb no-post') > /dev/null
    then 
      echo -e "${c_red}No Post flag was found. Review request was canceled.${c_std}"
      exit 0
    fi

    if (echo $msg | grep '#rb no-request') > /dev/null
    then 
        echo -e "${c_red}No Request flag was found. Review request will be send but not published ${c_std}"
        post-review --diff-filename=$fileDiff --description="$msg" --summary="[$projectName project] Diff between revisions [${oldrev:0:6} ${newrev:0:6}]" --target-groups=$group --username=$username --password=$password
		rm $fileDiff
    exit 0
   fi

   if (echo $msg | grep '#rb group') > /dev/null
   then
     found="#rb group "
     first=`expr index "$i" "$found"`
     lng=${#found} #str length
     let "end=$lng+$first"
     newStr="${i:$end}"
     set $newStr;

     if [ $1 !== "" ]
     then 
       echo -e "${c_red}Group flag was found but group name wasn't found${c_std}"   
     else 
        unset group
        group="$1"
        echo -e "${c_red}Group flag was found. This review will be published to $goup group${c_std}"
        post-review --diff-filename=$fileDiff --description="$msg" --summary="[$projectName project] Diff between revisions [${oldrev:0:6} ${newrev:0:6}]" --target-groups=$group --username=$username --password=$password -p 
		rm $fileDiff
        exit 0
     fi
   fi

   #main
   post-review --diff-filename=$fileDiff --description="$msg" --summary="[$projectName project] Diff between revisions [${oldrev:0:6} ${newrev:0:6}]" --target-groups=$group --username=$username --password=$password -p 
   rm $fileDiff
git st	
done


