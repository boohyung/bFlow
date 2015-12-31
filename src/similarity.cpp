    /*@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@
	@  similarity.cpp
	@  
	@  @AUTHOR:Kevin Zeng
	@  Copyright 2012 – 2015
	@  Virginia Polytechnic Institute and State University
	@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@#@*/

#include "similarity.hpp"


/**
 * euclidean
 *  Finds the euclidean distance
 */
double SIMILARITY::euclidean(std::map<std::string, unsigned>& data1, std::map<std::string,unsigned>& data2){
	assert(data1.size() == data2.size());
	std::map<std::string, unsigned>::iterator iMap;
	std::map<std::string, unsigned>::iterator iMap2;

	double sum = 0.0;
	iMap2 = data2.begin();
	for(iMap = data1.begin(); iMap != data1.end(); iMap++){
		if(iMap2->first == iMap2->first){
			sum += (double)abs((iMap->second - iMap2->second));
			iMap2++;
		}
		else throw cException("(SIMILARITY::euclidean) FP Type name doesn't match");
	}

	return (sum);
}

/**
 * euclidean
 *  Finds the euclidean distance
 */
double SIMILARITY::euclidean(std::vector<unsigned>& data1, std::vector<unsigned>& data2){
	assert(data1.size() == data2.size());

	double sum = 0.0;
	for(unsigned int i =  0; i < data1.size(); i++)
		sum += (double)abs((data1[i]- data2[i]));

	return (sum);
}

/**
 * euclidean
 *  Finds the euclidean distance
 */
double SIMILARITY::euclidean(std::vector<int>& data1, std::vector<int>& data2){
	unsigned int smallSize;  
	if(data1.size() < data2.size())
		smallSize = data1.size();
	else smallSize = data2.size();

	double sum = 0.0;
	for(unsigned int i =  0; i < smallSize; i++)
		sum += (double)abs((data1[i]- data2[i]));

	
	if(data1.size() < data2.size())
		for(unsigned int i =  smallSize; i < data2.size(); i++)
			sum += (double)abs(data2[i]);
	else
		for(unsigned int i =  smallSize; i < data1.size(); i++)
			sum += (double)abs(data1[i]);
	
	return sum;
}



/**
 * cosine 
 *  Finds the cosine similarity of two dataset 
 */
double SIMILARITY::cosine(std::map<unsigned, unsigned>& data1, std::map<unsigned,unsigned>& data2){
	if(data1.size() == 0 || data2.size() == 0) return 0.0;
	std::map<unsigned, unsigned>::iterator iMap;
	std::map<unsigned, unsigned>::iterator iMap2;
	std::map<unsigned, unsigned>::iterator iTemp;
	std::map<unsigned, unsigned>::iterator iMapF;
	std::set<unsigned> marked1;
	std::set<unsigned> marked2;

	int anorm = 0;
	for(iMap = data1.begin(); iMap != data1.end(); iMap++)
		anorm += (iMap->second * iMap->second);
	
	int bnorm = 0;
	for(iMap = data2.begin(); iMap != data2.end(); iMap++)
		bnorm += (iMap->second * iMap->second);

	double denom = sqrt((double)anorm) * sqrt((double)bnorm);


	//Count the number of bits that are the same
	double sum = 0.0;
	for(iMap = data1.begin(); iMap != data1.end(); iMap++){
		iTemp = data2.find(iMap->first);	
		if(iTemp != data2.end())
			sum += (double)(iTemp->second * iMap->second);
	}
	
	return sum / denom;
}

/**
 * cosine 
 *  Finds the cosine similarity of two dataset 
 */
double SIMILARITY::cosine(std::vector<unsigned>& data1, std::vector<unsigned>& data2){
	assert(data1.size() == data2.size());
	if(data1.size() == 0 || data2.size() == 0) return 0.0;

	int anorm = 0;
	for(unsigned int i =  0; i < data1.size(); i++)
		anorm += (data1[i] * data1[i]);
	
	int bnorm = 0;
	for(unsigned int i =  0; i < data2.size(); i++)
		bnorm += (data2[i] * data2[i]);

	double denom = sqrt((double)anorm) * sqrt((double)bnorm);


	//Count the number of bits that are the same
	double sum = 0.0;
	for(unsigned int i =  0; i < data1.size(); i++)
		sum += (double)(data1[i]* data2[i]);
	
	return sum / denom;
}



/**
 * Resemblance 
 *   Resemblance formula for two sets of KGRAM SET AND LIST BASE
 */

double SIMILARITY::resemblance(std::map<std::string,int>& data1, std::map<std::string, int>& data2, bool partialMatch, bool countMatch){
	double intersection = 0.0;
	double numunion= 0.0;
	double total1 = 0.0;

	//Goes through and finds the grams that are the same
	std::set<std::string> marked;
	std::map<std::string, int>::iterator iMap;
	for(iMap = data1.begin(); iMap != data1.end(); iMap++){
		double size = (double) iMap->first.size();

		if(countMatch) total1+= (size *2.0);
		else           total1+= (size );

		//Intersection is the number of grams that are shared between the two
		std::map<std::string, int>::iterator iMap2;
		iMap2 = data2.find(iMap->first);

		if(iMap2 != data2.end()){
			//larger q-grams have a higher weight as well as two kgrams with close counts

			if(countMatch){
				std::map<std::string, int>::iterator iMap2;
				iMap2 = data2.find(iMap->first);
				double count2 = (double) iMap2->second;
				double countRatio = iMap->second > count2? 
														count2 / (double) iMap->second : 
														(double) iMap->second / count2;
				intersection +=  (size + countRatio*size);
			}
			else
				intersection +=  (size);

		}
		else if(iMap->first.size() > 1){ //Partial kgram match
			if(partialMatch){
				std::string maxString = alignKGram(iMap->first, data2, marked);

				if(maxString != ""){
					int idealScore1 = align(iMap->first, iMap->first);
					int idealScore2 = align(maxString, maxString);
					double matchScore  = (double) align(iMap->first, maxString);
					double idealScore  = (double) idealScore1 < idealScore2 ? (double) idealScore1 : (double) idealScore2;

					double result =  matchScore / idealScore;

					if(result >0.8) //Is the result significant enough 
					{
						marked.insert(maxString);
						if(countMatch){
							double count2 = (double) data2[maxString];
							double countRatio = iMap->second > count2? 
																	count2 / (double) iMap->second : 
																	(double) iMap->second / count2;
							std::map<std::string, int>::iterator iMap2;
							iMap2 = data2.find(iMap->first);

							intersection += (result * size) + countRatio * size ;
						}
						else           intersection += (result * size); 
						//printf("INTERSECTION: %f MAT: %d  IDEAL: %d  RESULT: %f", intersection, matchScore, idealScore, result);
						//printf("   RGRAM: |%8s| - |%8s| \n", iMap->first.c_str(), maxString.c_str());
						//printf("   RGRAM: |%s| - |%s|  SCORE: %5.3f  MAT: %3d  ID1: %d ID2: %d\n\n", iMap->first.c_str(), maxString.c_str(), result, matchScore, idealScore1, idealScore2);
					}
					else{
						//printf("NO GRAM:  %8s - %8s  SCORE: %5.2f  MAT: %3d  ID1: %d ID2: %d\n", iMap->first.c_str(), maxString.c_str(),result, matchScore, idealScore1, idealScore2);
					}
				}
			}
		}
	}
	
	double total2 = 0.0;
	//Find the kgrams that are in the second one that are not by the datai1
	for(iMap = data2.begin(); iMap != data2.end(); iMap++){
		if(countMatch) total2+= (double) iMap->first.size() *2.0;
		else total2+= (double) iMap->first.size();

	}
			
	//printf("INTERSECTION: %f\n", intersection);
	//printf("union: %ff\n", total1+total2-intersection);

	//Union is the number of shared + the number of items not shared in 1 and 2
	numunion = total1 + total2 - intersection;
	if(numunion == 0.0)
		return 0.0;

//printf("total1 : %f\ttotal2: %f\n", total1, total2);

//printf("INTER: %f\tUNION: %f\n", intersection, numunion);

	return intersection / numunion;
}



/**
 * Containment 
 *   Containment formula for two sets of KGRAM SET AND LIST BASE
 *   Data1 is the smaller or query circuit
 */

double SIMILARITY::containment(std::map<std::string,int>& data1, std::map<std::string, int>& data2, bool countMatch){
	double intersection = 0.0;
	double total = 0.0;
	if(data1.size() == 0 || data2.size() == 0)
		return 0.0;

	std::map<std::string, int>::iterator iMap;
	for(iMap = data1.begin(); iMap != data1.end(); iMap++){
		//Intersection is the number of grams that are shared between the two
		double size = (double) iMap->first.size();
		if(countMatch) total += size * 2.0;
		else 				   total += size;
		

		if(data2.find(iMap->first) != data2.end()){
			if(countMatch){
				std::map<std::string, int>::iterator iMap2;
				iMap2 = data2.find(iMap->first);
				double count2 = (double) iMap2->second;
				double countRatio = iMap->second > count2? 
														count2 / (double) iMap->second : 
														(double) iMap->second / count2;
				intersection +=  (size + countRatio*size);

			}
			else intersection += (double)iMap->first.size();

		}
	}

	//printf("NUM: %f\tDEN: %d\n", intersection, data2.size());
	return intersection / total;
	
}


/**
 * Resemblance 
 *   Resemblance formula for two sets of KGRAM
 */

double SIMILARITY::resemblance(std::map<std::map<char,int>, int>& data1, std::map<std::map<char, int>, int>& data2){
	double intersection = 0.0;
	double numunion= 0.0;
	double total1 = 0.0;
	double total2 = 0.0;

	std::map<std::map<char, int>, int>::iterator iMap;
	std::map<char, int>::const_iterator iMapC;
	for(iMap = data1.begin(); iMap != data1.end(); iMap++){
		//Count how long the gram is 
		int size = 0;
		for(iMapC = iMap->first.begin(); iMapC != iMap->first.end(); iMapC++)
			size += iMapC->second;

		total1+= (double) size;
		//Intersection is the number of grams that are shared between the two
		if(data2.find(iMap->first) != data2.end())
			intersection +=(double) size;
	}
	
	for(iMap = data2.begin(); iMap != data2.end(); iMap++){
		int size = 0;
		for(iMapC = iMap->first.begin(); iMapC != iMap->first.end(); iMapC++)
			size += iMapC->second;
		
		total2+= (double) size;
	}

	//Union is the number of shared + the number of items not shared in 1 and 2
	numunion = total1 + total2 - intersection;
	if(numunion == 0.0) return 0.0;

	return intersection / numunion;
}



/**
 * Containment 
 *   Containment formula for two sets of KGRAM
 *   Data2 is the smaller or query circuit
 */

double SIMILARITY::containment(std::map<std::map<char,int>, int>& data1, std::map<std::map<char,int>, int>& data2){
	if(data2.size()== 0) return 0.0;
	double intersection = 0.0;
	double total = 0.0;

	std::map<std::map<char, int>, int>::iterator iMap;
	for(iMap = data1.begin(); iMap != data1.end(); iMap++){
		total += (double)iMap->first.size();
		//Intersection is the number of grams that are shared between the two
		if(data2.find(iMap->first) != data2.end())
			intersection += (double)iMap->first.size();
	}

	//printf("NUM: %f\tDEN: %d\n", intersection, data2.size());
	return intersection / total;
}





/**
 * align 
 *  align the sequences and extract
 *  the similarity of the alignment (AVG SIM) 
 */
int SIMILARITY::align(std::string str1, std::string str2){
	//Assign the alignment structure with the sequences
	//s_Align and s_Score initialized in initAlignment
	TSequence seq1 = str1;
	TSequence seq2 = str2;
	assignSource(row(s_Align, 0), seq1);
	assignSource(row(s_Align, 1), seq2);
	
	//Alignment of the sequence
	int score = localAlignment(s_Align, s_Score);
	//printf("[SIM] -- %5d   ALIGN: %s - %s\n==================\n", score, iRef->c_str(), iSeq->c_str());

	return score;
}
	



/**
 * alignKGram
 *   Find the closest matching gram in the list that matches the string
 */
std::string SIMILARITY::alignKGram(std::string str, std::map<std::string, int>& gram, std::set<std::string>& marked){
	std::map<std::string, int>::iterator iMap;

	int maxScore = 0;
	std::string maxScoreString = "";
	for(iMap = gram.begin(); iMap != gram.end(); iMap++){
		if(marked.find(iMap->first) != marked.end())
			continue;
			
		//if(iMap->first.length() <= str.length()+1 && iMap->first.length() >= str.length() -1){
		if(iMap->first.length() == str.length()){
			int score = align(iMap->first, str);
			//printf("COMPARE: !%s! - !%s! : SCORE: %d\n", str.c_str(), iMap->first.c_str(), score);
			if(score > maxScore){
				maxScore = score;
				maxScoreString = iMap->first;
			}
		}
	}

	//int score = align(str, maxScoreString);
	//printAlignment();
	//int idealScore = align(maxScoreString, maxScoreString);
	//printf("MGRAM: %8s ID: %d\n", maxScoreString.c_str(), idealScore);
	return maxScoreString;
}





/**
 * alignList 
 *  given a list of sequences (REF and DB), align the sequences and extract *  the similarity of the alignment (AVG SIM) 
 */
int SIMILARITY::alignList(std::list<std::string>& ref, std::list<std::string>& db, bool output){
	//	timeval start_time, end_time;
	//	gettimeofday(&start_time, NULL); //----------------------------------

	std::list<std::string>::iterator iSeq;	
	std::list<std::string>::iterator iRef;	
	unsigned totalScore = 0;

	for(iRef= ref.begin(); iRef!= ref.end(); iRef++){
		for(iSeq = db.begin(); iSeq != db.end(); iSeq++){
			//Assign the alignment structure with the sequences
			TSequence seq1 = *iRef;
			TSequence seq2 = *iSeq;
			//printf("S1 %s - S2%s\n", iRef->c_str(), iSeq->c_str());
			assignSource(row(s_Align, 0), seq1);
			assignSource(row(s_Align, 1), seq2);
			
			//Alignment of the sequence
			int score = localAlignment(s_Align, s_Score);
			//printAlignment();

			//Calcuate the difference in the size ratios
			/*
			double sizeRatio = 0;
			if(iRef->length() < iSeq->length())
				sizeRatio = (double)iRef->length()/ (double)iSeq->length();
			else
				sizeRatio = (double)iSeq->length()/ (double)iRef->length();
				*/


			//Go through the aligned sequence and add additional gap penalty
      /*
      GAP PENALTY MATRIX NEEDS TO BE UPDATED. OTHERWISE IGNORE
			TRowIterator it1 = begin(row(s_Align,0));
			TRowIterator it2 = begin(row(s_Align,1));
			TRowIterator it1End = end(row(s_Align,0));
			for (; it1 != it1End; ++it1){
				if (isGap(it1))      score += CircuitGapPenaltyMatrix[*it2];
				else if(isGap(it2))  score += CircuitGapPenaltyMatrix[*it1];
				++it2;
			}
      */

				//printf("[SIM] -- %5d \n", score );
       if(output)
				printf("[SIM] -- %5d   ALIGN: %s - %s\n==================\n", score, iRef->c_str(), iSeq->c_str());
			//Sum the entire score
			//totalScore += (score*sizeRatio);
			totalScore += (score);
		}
	}

	return totalScore;
}




/**
 * printAlignment 
 *  Prints the result of the alignment 
 */
void SIMILARITY::printAlignment(){
	TRowIterator it1 = begin(row(s_Align,0));
	TRowIterator it2 = begin(row(s_Align,1));
	TRowIterator it1End = end(row(s_Align,0));
	TRowIterator it2End = end(row(s_Align,1));
	for (; it1 != it1End; ++it1){
		if (isGap(it1))    std::cout << gapValue<char>();
		else              std::cout << *it1;
	}
	std::cout << std::endl;

	it1 = begin(row(s_Align,0));
	it2 = begin(row(s_Align,1));
	for (; it1 != it1End; ++it1){
		if (isGap(it1))         std::cout << "*" ;
		else if(isGap(it2))     std::cout << "*" ;
		else if(*it2 != *it1)  	std::cout << "X";
		else                    std::cout << "|";
		++it2;
	}
	std::cout << std::endl;

	it1 = begin(row(s_Align,0));
	it2 = begin(row(s_Align,1));
	for (; it2 != it2End; ++it2){
		if (isGap(it2))   std::cout << gapValue<char>();
		else              std::cout << *it2;
	}
	std::cout << std::endl;
}

/**
 * initAlignment 
 *   Initializes the alignment to do pairwise alignment
 *   Sets the default score matrix
 */
void SIMILARITY::initAlignment(){
	//Set up the aligner
	resize(rows(s_Align), 2);

	//Set up the scoring scheme using a custom scoring matrix
	//Located in lib/seqan/score/scorematrixwithdata
	setDefaultScoreMatrix(s_Score, CircuitScoringMatrix());
	//showScoringMatrix(s_Score);

}










/**
 * findMinDistance
 *  Finds the size who's distance is the mininum to a value 
 */
int SIMILARITY::findMinDistance(std::map<unsigned, unsigned>& data, std::set<unsigned>& marked, unsigned value, std::map<unsigned, unsigned>::iterator& minIt){
	std::map<unsigned, unsigned>::iterator iMap;
	int minDiff = 10000;

	for(iMap= data.begin(); iMap!= data.end(); iMap++){
		//If the difference is greater than window size, continue;
		int difference = iMap->first - value;
		if(difference < 0) difference *= -1;


		if(difference < minDiff){
			//Check to see if it has been marked before
			if(marked.find(iMap->first) != marked.end()) continue;
			minDiff = difference;
			minIt = iMap;
		}
	}
	return minDiff;

}



/**
 * tanimotoWindow_size 
 *  Finds the tanimoto coefficient using a 5 space window technique
 *  Disregards the count
 */
double SIMILARITY::tanimotoWindow_size(std::map<unsigned, unsigned>& data1, std::map<unsigned,unsigned>& data2){
	if(data1.size() == 0 || data2.size() == 0){
		//return -1.0;
		return 0.0;
	}
	double N_f1 = data1.size();
	double N_f2 = data2.size();

	//Count the number of 1's in the second fingerprint
	const int windowSize = 5;
	double N_f1f2_ratio = 0.0;

	std::map<unsigned, unsigned>::iterator iMap;
	std::map<unsigned, unsigned>::iterator iMap2;
	std::map<unsigned, unsigned>::iterator iTemp;
	std::map<unsigned, unsigned>::iterator iMapF;
	std::set<unsigned> marked1;
	std::set<unsigned> marked2;

	std::map<unsigned, unsigned> temp;
	std::map<unsigned, unsigned> map;

	const double multiplier[windowSize+1] = {
		1.000, 0.9938, 0.9772, 0.9332, 0.8413, 0.6915
	};


	//Count the number of bits that are the same
	for(iMap = data1.begin(); iMap != data1.end(); iMap++){
		iTemp = data2.find(iMap->first);	

		if(iTemp != data2.end()){
			//printf("Both sets have : %d\n", iTemp->first); 
			N_f1f2_ratio += 1.000;

			marked1.insert(iMap->first);
			marked2.insert(iTemp->first);
		}
	}

	//Go through the vector again and try and find similar matches in the bits (WINDOWING)
	for(iMap = data1.begin(); iMap != data1.end(); iMap++){
		if(marked1.find(iMap->first) == marked1.end()){
			int minDistance1 = findMinDistance(data2, marked2, iMap->first, iTemp);
			int minDistance2 = findMinDistance(data1, marked1, iTemp->first, iMapF);

			//There exists a shorter distance
			if(iMapF->first != iMap->first){
				continue;
			}
			else if(minDistance1 != minDistance2) continue;

			//Similar size found within window
			if(minDistance1 <= windowSize){
				double ratio = multiplier[minDistance1];

				N_f1f2_ratio += ratio;
				marked1.insert(iMap->first);
				marked2.insert(iTemp->first);
			}
		}
	}

	double denom = (N_f1+N_f2-N_f1f2_ratio);
	if(denom == 0.0)	return 0.0;

	return N_f1f2_ratio / denom;
}








/**
 * tanimotoWindow
 *  Finds the tanimoto coefficient using a 5 space window technique
 *  Takes the count into account
 */
double SIMILARITY::tanimotoWindow(std::map<unsigned, unsigned> data1, std::map<unsigned,unsigned> data2){
	if(data1.size() == 0 || data2.size() == 0){
		//return -1.0;
		return 0.0;
	}
	double N_f1 = data1.size();
	double N_f2 = data2.size();

	//Count the number of 1's in the second fingerprint
	const int windowSize = 2;
	double N_f1f2_ratio = 0.0;

	std::map<unsigned, unsigned>::iterator iMap;
	std::map<unsigned, unsigned>::iterator iMap2;
	std::map<unsigned, unsigned>::iterator iTemp;
	std::map<unsigned, unsigned>::iterator iMapF;
	std::set<unsigned> marked1;
	std::set<unsigned> marked2;

	const double multiplier[windowSize+1] = {
		1.000, 0.9332, 0.6915
			//1.000, 0.9938, 0.9772, 0.9332, 0.8413, 0.6915
	};

	//Count the number of bits that are the same
	for(iMap = data1.begin(); iMap != data1.end(); iMap++){
		iTemp = data2.find(iMap->first);	
		//printf("Looking for %d in data1...", iMap->first);

		if(iTemp != data2.end()){
			//printf("Both data has: %d\n", iTemp->first);
			double ratio;
			if(iMap->second > iTemp->second){
				ratio = ((double)iTemp->second / (double)iMap->second);
				marked2.insert(iTemp->first);
				iMap->second = iMap->second - iTemp->second;
				//printf("data 1- %d: has %d left unmapped\n", iMap->first, iMap->second);
			}
			else if(iTemp->second >  iMap->second){
				ratio = ((double)iMap->second / (double)iTemp->second);
				marked1.insert(iMap->first);
				iTemp->second = iTemp->second - iMap->second;
				//printf("data 2- %d: has %d left unmapped\n", iTemp->first, iTemp->second);
			}
			else{
				//printf("EQUAL COUNTS\n");
				ratio = 1.000;
				marked1.insert(iMap->first);
				marked2.insert(iTemp->first);
			}
			N_f1f2_ratio += ratio;
		}
		//else printf("\n");
	}

	//Go through the vector again and try and find similar matches in the bits (WINDOWING)
	//printf("\nWindowing on data1:\n");
	for(iMap = data1.begin(); iMap != data1.end(); iMap++){
		//printf("Checking %d\n", iMap->first);
		if(marked1.find(iMap->first) == marked1.end()){
			//printf("*Not Marked\n");
			int minDistance1 = findMinDistance(data2, marked2, iMap->first, iTemp);
			int minDistance2 = findMinDistance(data1, marked1, iTemp->first, iMapF);

			//There exists a shorter distance
			if(iMapF->first != iMap->first){
				continue;
			}
			else if(minDistance1 != minDistance2) continue;

			//Similar size found within window
			if(minDistance1 <= windowSize){
				double ratio;



				if(iMap->second > iTemp->second){
					marked2.insert(iTemp->first);
					//printf("data 1- %d: has %d left unmapped\n", iMap->first, iMap->second-iTemp->second);
					ratio = ((double)iTemp->second / (double)iMap->second);
					iMap->second = iMap->second - iTemp->second;
				}
				else if(iTemp->second >  iMap->second){
					marked1.insert(iMap->first);
					//printf("data 2- %d: has %d left unmapped\n", iTemp->first, iTemp->second-iMap->second);
					ratio = ((double)iMap->second / (double)iTemp->second);
					iTemp->second = iTemp->second - iMap->second;
				}
				else{
					ratio = 1.000;
					//printf("EQUAL COUNTS\n");
					marked1.insert(iMap->first);
					marked2.insert(iTemp->first);
				}




				ratio = multiplier[minDistance1]*ratio;// * (1.0 - ratio);

				N_f1f2_ratio += ratio;
				marked1.insert(iMap->first);
				marked2.insert(iTemp->first);
			}
		}
		//printf("\n");
	}

	double denom = (N_f1+N_f2-N_f1f2_ratio);
	if(denom == 0.0)	return 0.0;

	return N_f1f2_ratio / denom;
}





/**
 * tanimoto
 *  Finds the tanimoto coefficient
 */
double SIMILARITY::tanimoto(std::set<int>& data1, std::set<int>& data2){
	double N_f1 = data1.size();
	double N_f2 = data2.size();

	//Count the number of 1's in the second fingerprint
	double N_f1f2_ratio = 0.0;

	std::set<int>::iterator iMap;
	std::set<int>::iterator iTemp;

	//Count the number of bits that are the same
	for(iMap = data1.begin(); iMap != data1.end(); iMap++){
		iTemp = data2.find(*iMap);	

		if(iTemp != data2.end()){
			N_f1f2_ratio += 1.000;
		}
	}


	double denom = (N_f1+N_f2-N_f1f2_ratio);
	if(denom == 0.0)	return 0.0;

	return N_f1f2_ratio / denom;
}


/**
 * tanimoto
 *  Finds the tanimoto coefficient
 */
double SIMILARITY::tanimoto(std::map<unsigned, unsigned>& data1, std::map<unsigned, unsigned>& data2){
	double N_f1 = data1.size();
	double N_f2 = data2.size();

	//Count the number of 1's in the second fingerprint
	double N_f1f2_ratio = 0.0;

	std::map<unsigned, unsigned>::iterator iMap;
	std::map<unsigned, unsigned>::iterator iTemp;

	//Count the number of bits that are the same
	for(iMap = data1.begin(); iMap != data1.end(); iMap++){
		iTemp = data2.find(iMap->first);	

		if(iTemp != data2.end()){
			N_f1f2_ratio += 1.000;
		}
	}


	double denom = (N_f1+N_f2-N_f1f2_ratio);
	if(denom == 0.0)	return 0.0;

	return N_f1f2_ratio / denom;
}
