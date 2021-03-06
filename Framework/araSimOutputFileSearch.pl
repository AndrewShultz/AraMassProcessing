#!/usr/bin/perl
use Cwd;

use File::Basename;

#this script collects files to process given a level number

#function to run all the function in this script and pass appropriate arguments
sub start {
    $level = @_[0];
    $resultPath = @_[1];

    $resultPathInput = $resultPath . "/Input/";
    sub getFileList;
    ($fileListArr, $tot) = getFileList($level, $resultPath);

    $totFiles = $tot;

    $fileName1 = $resultPathInput . "/inputFilesToProcess.txt";

    printFileList($fileListArr, $fileName1);
    ($textFileName) = generateTextFileName($level, $resultPathInput);

    $limit = 2;

    ($totalJobs) = loadBalance($fileName1, $level, $limit, $totFiles, $resultPathInput);
    return ($level);
}



sub getFileList {
    #this function collects appropriate file names depending on the level of the merge
    #and saves them into an array

    my $levelNumber = @_[0];
    my $resultPath =@_[1];

    my $directoryPath = $resultPath;
    my $oneLineResults;
    $fileTemplate = "levelOut_"."$levelNumber"."_*.root";
    if($levelNumber == 0){
	$oneLineResults = `find $directoryPath -name \"AraOut.*.root\"`;
    }else {
	$decrLevel = $levelNumber - 1;
	$fileTemplate = "mergeOutput_".$decrLevel."_"."*.root";	
	$oneLineResults = `find $directoryPath -name \"$fileTemplate\"`;
    }
    
    my @fileList = split /\n/, $oneLineResults;
    for my $line (@fileList){
	#print "line is $line \n";
    }
    $tot = @fileList;
    return (\@fileList, $tot);
}

sub printFileList {
    #takes array and writes content into text file

    my @list = @{@_[0]};
    my $fileName = @_[1];
    open(FILE, ">$fileName") or die "Cannot open file $fileName : $!\n";
    for my $line (@list) {
	print FILE "$line\n";
    }
}

sub loadBalance {
    #this function balances input files per job
    #handles even number of input files

    my $input = @_[0];
    my $levelNumber =@_[1];
    my $limit =@_[2];
    my $totNumberOfFiles =@_[3];
    my $resultPath =@_[4];
    
    #checks to see if number of files is even or odd
    if( $totNumberOfFiles % 2 == 1){
	$isOdd = 1;
    }

   
    my $counter = 0;
    if( $isOdd == 1){
	loadBalanceOdd($input, $levelNumber, $resultPath);
	$input = "$resultPath/temp.txt";
	$counter = 2;
    }
    open(FILE, "$input");
    ($prefix) = generateTextFileName($levelNumber, $resultPath);
    $postfix =".txt";
    $output = undef;
    while(<FILE>){
	if($counter % $limit == 0){
	    #   $limit =int(2);  # set to 2 in case the number of files was odd
	    
	    if(defined($output)){
		close(OUTPUT);
	    }
	    
	    $output = open(OUTPUT, ">$prefix". int($counter/$limit) . "$postfix\n");
	    print "$output \n";
	}
	chomp;
	print OUTPUT "$_\n";
	
	$counter = $counter + 1;

    }
    close(FILE);

    $totalFiles = 1 + int(($counter - 1)/$limit);   
    return ($totalFiles);

}

sub getTotalNumberOfFiles {
    # this function returns the number of files to collect on each level
    my @arrayList = @_[0];
    my $tot = @arrayList;
    return ($tot);
}

sub generateTextFileName {
    my $levelNumber = @_[0];
    my $resultPath =@_[1];

    #generating text file for each level
    #level 0 files => have the form of AraOut.*.root
    #level 1, 2, 3,... => have the form of level_$_&.root => where $ is the level number, and & is the $(Process)

    #textFile have the format of
    #inputLevel_$_&.txt => where $ is the level of merging and & is the $(Process)

    my $textFileName = $resultPath . "inputFile_". "$levelNumber"."_"; #."_".$processNumber.".txt";
    return ($textFileName);

}


sub loadBalanceOdd {

    #this function handles odd number of files to process
    $input = @_[0];
    $levelNumber = @_[1];
    $resultPath =@_[2];

    open(FILE, "$input");

    $count= 0;
    $prefix = generateTextFileName($levelNumber, $resultPath);
    $postfix = ".txt";
    $tempFile= "$resultPath/temp.txt";

    while(<FILE>){
	if($count < 3){
	    if($count == 0){
		$output = open(OUTPUT, ">$prefix". int($count) . "$postfix\n");
	    }
	    chomp;
	    print OUTPUT "$_\n";
	    $count = $count + 1;

	}else{
	    if($count == 3){
		if(defined($output)){
		    close OUTPUT;
		}
		$output = open(OUTPUT, ">$tempFile");
	    }
	    chomp;
	    print OUTPUT "$_\n";
	    $count = $count + 1;
	}

    }
    close(FILE);
    if(defined($output)){
	close OUTPUT;
    }
}

sub checkFileSize {

    #this function checks if the file size of a file is not greater than the file size wanted  
    # returns 0 if the size limit has been reached
    my $sizeLimit = @_[0];
    my $level = @_[1];
    my $flag = @_[2];
    my $resultPath =@_[3];

    $resultPath = "$resultPath/Temp/";
    my $fileName;
    if($flag == 0){
        $fileName = $resultPath . "/AraOut.setup.txt.run0.root";
    }else {
        $fileName = $resultPath . "/mergeOutput_".$level."_0.root";
    }

    my $fileSize = `stat --format=%s $fileName`;
    if($fileSize > $sizeLimit){
        return 0;
    }else{
        return 1;
    }

}
