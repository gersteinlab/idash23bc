// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.12;

/*
 * Team Name: Gerstein Lab
 *
 *   Team Member 1:
 *       { Name: Eric Ni, Email: eric.ni@yale.edu }
 *   Team Member 2:
 *       { Name: Gaoyuan Wang, Email: gaoyuan.wang@yale.edu }
 *   Team Member 3:
 *       { Name: Andy Chu, Email: andy.chu@yale.edu }
 *   Team Member 4:
 *       { Name: Yuhang Chen , Email: yuhang.chen@yale.edu }
 *
 * Declaration of cross-team collaboration:
 *	We DO NOT collaborate with any team.
 *
 * REMINDER
 *	No change to function declarations is allowed.
 */

contract DynamicConsent {
    /**
     *   If a WILDCARD (-1) is received as function parameter, it means any value is accepted.
     *   For example, if _studyID = -1 in queryForPatient,
     *	then we expected all consents made by the patient within the appropriate time frame
     *	regardless of studyID.
     */

    // Storage variables/constants
    int256 private constant WILDCARD = -1;

    uint256 gCounter = 1;

    uint256 eCounter = 0;

    uint256[] EMPTYARRAY = new uint256[](0);

    bytes32 private constant EMPTYSTRING = keccak256(bytes(""));

    // Structs

    struct Entry {
        int256 patientID;
        int256 studyID;
        uint256 timestamp;
    }

    // mappings

    // globalID=> entry
    mapping(uint256 => Entry) entryDatabase;
    // globalID => choices
    mapping(uint256 => uint256[]) catChoicesDatabase;
    mapping(uint256 => uint256[]) eleChoicesDatabase;

    // patientID => studyID => list of globalID
    mapping(int256 => mapping(int256 => uint256[])) queryMapping;

    // choice ID => choice name
    mapping(uint256 => string) choicesDict;
    // choice name => choice ID
    mapping(string => uint256) choicesLookup;
    // studyID => patientIDs
    mapping(uint256 => int256[]) study2patients;

    constructor() {}

    // MAIN FUNCTIONS

    /**
     *   Function Description:
     *	Given a patientID, studyID, recordTime, consented category choices, and consented element choices,
     *   store a patient's consent record on-chain.
     *   Parameters:
     *       _patientID: uint256
     *       _studyID: uint256
     *       _recordTime: uint256
     *       _patientCategoryChoices: string[] calldata
     *       _patientElementChoices: string[] calldata
     */
    function storeRecord(
        uint256 _patientID,
        uint256 _studyID,
        uint256 _recordTime,
        string[] calldata _patientCategoryChoices,
        string[] calldata _patientElementChoices
    ) public {
        // Store entry in entryDatabase
        int256 iPatientID = int(_patientID);
        int256 iStudyID = int(_studyID);

        entryDatabase[gCounter] = Entry({patientID: iPatientID, studyID: iStudyID, timestamp: _recordTime});

        uint256 c = _patientCategoryChoices.length;
        uint256 e = _patientElementChoices.length;
        bytes memory b;
        uint256 ce;
        uint i;

        unchecked {
            for (i = 0; i < c; i++) {
                b = bytes(_patientCategoryChoices[i]);
                // convert category/element string to int: ex "11_05" becomes 1105
                ce = uint256((uint8(b[0]) - 48) * 10 + (uint8(b[1]) - 48));
                // store it
                catChoicesDatabase[gCounter].push(ce);
                // if we haven't seen this category/element yet
                if (keccak256(bytes(choicesDict[ce])) == EMPTYSTRING) {
                    // keep track of what the string was
                    choicesDict[ce] = _patientCategoryChoices[i];
                    choicesLookup[_patientCategoryChoices[i]] = ce;
                }
            }

            for (i = 0; i < e; i++) {
                b = bytes(_patientElementChoices[i]);
                ce = uint256((uint8(b[0]) - 48) * 1000 + ((uint8(b[1]) - 48) * 1000) / 10 + (uint8(b[3]) - 48) * 10 + (uint8(b[4]) - 48));

                eleChoicesDatabase[gCounter].push(ce);
                // if we haven't seen this category/element yet
                if (keccak256(bytes(choicesDict[ce])) == EMPTYSTRING) {
                    // keep track of what the string was
                    choicesDict[ce] = _patientElementChoices[i];
                    choicesLookup[_patientElementChoices[i]] = ce;
                }
            }

            if (queryMapping[iPatientID][iStudyID].length == 0) {
                // check whether the patient id has been linked to the study id
                study2patients[_studyID].push(iPatientID);
            }

            // For all possible queries of patient ID and study ID, append globalID to querymap
            queryMapping[iPatientID][iStudyID].push(gCounter);
            queryMapping[iPatientID][-1].push(gCounter);
            gCounter++;
        }
    }

    /**
     *   Function Description:
     *	Given a studyID, endTime, requested category choices, and requested element choices,
     *	return a list of patientIDs that have consented to share with the study
     *	at least the requested categories and elements,
     *	and such consent was timestamped at or before _endTime.
     *	If there are several consents from the same patient for the same studyID
     *	made within the indicated timeframe
     *	then only the most recent one should be considered.
     *   Parameters:
     *      _studyID: uint256
     *      _endTime: int256
     *      _requestedCategoryChoices: string[] calldata
     *      _requestedElementChoices: string[] calldata
     *   Return:
     *       Array of consenting patientIDs: uint256[] memory
     */
    function queryForResearcher(
        uint256 _studyID,
        int256 _endTime,
        string[] calldata _requestedCategoryChoices,
        string[] calldata _requestedElementChoices
    ) public view returns (uint256[] memory) {
        uint256[] memory result;
        unchecked {
            uint256[] memory LatestIDs;
            int256[] memory pIDList;
            // this gets a table of latest IDs for each patient in the study up to endtime
            (LatestIDs, pIDList) = getLatestIDs(_studyID, _endTime);
            uint256 h = LatestIDs.length;
            if (h == 0) {
                return EMPTYARRAY;
            }
            uint256 resultCounter;
            result = new uint256[](LatestIDs.length);

            // convert every element/category to int
            uint256[] memory RequestCategory = getCategoryIndex(_requestedCategoryChoices);
            uint256[] memory RequestElement = getElementIndex(_requestedElementChoices);

            uint256[] memory PatientCategory;
            uint256[] memory PatientElement;
            for (uint256 i = 0; i < h; i++) {
                PatientCategory = catChoicesDatabase[LatestIDs[i]];
                PatientElement = eleChoicesDatabase[LatestIDs[i]];
                if (isMatch(PatientCategory, RequestCategory, PatientElement, RequestElement)) {
                    resultCounter++;
                    assembly {
                        mstore(add(result, mul(resultCounter, 32)), mload(add(add(pIDList, 32), mul(i, 32))))
                    }
                }
            }
            assembly {
                mstore(result, resultCounter)
            }
            if (resultCounter == 0) {
                return EMPTYARRAY;
            }
        }

        return result;
    }

    /**
     *   Function Description:
     *	Given a patientID, studyID, search start time, and search end time,
     *	return a concatenated string of the patient's consent history.
     *	The expected format of the returned string:
     *		Within the same consent: fields separated by comma.
     *		More than one consent returned: consents separated by newline character.
     *   For e.g:
     *		"studyID1,timestamp1,categorySharingChoices1,elementSharingChoices1\nstudyID2,timestamp2,categorySharingChoices2,elementSharingChoices2\n"
     *   Parameters:
     *       _patientID: uint256
     *       _studyID: int256
     *       _startTime: int256
     *       _endTime: int256
     *   Return:
     *       String of concatenated consent history: string memory
     */
    function queryForPatient(uint256 _patientID, int256 _studyID, int256 _startTime, int256 _endTime) public view returns (string memory) {
        uint256[] memory hits = queryMapping[int(_patientID)][_studyID];
        uint256 h = hits.length;
        string memory result;

        unchecked {
            if (h == 0 || _startTime > int(entryDatabase[hits[h - 1]].timestamp) || ((_endTime < int(entryDatabase[hits[0]].timestamp)) && _endTime != -1)) {
                return result;
            }

            string memory temp;

            int len;
            uint dest;
            uint src;
            uint256 i;
            bool init;

            uint256 startIndex;
            uint256 endIndex;

            if (h > 10) {
                // do binary search

                if (_startTime == -1) {
                    startIndex = 0;
                } else {
                    startIndex = binarySearchStart(hits, _startTime);
                }
                if (_endTime == -1) {
                    endIndex = h - 1;
                } else {
                    endIndex = binarySearchEnd(hits, _endTime);
                }
            } else {
                // do linear search

                if (_startTime == -1) {
                    startIndex = 0;
                } else {
                    for (startIndex = 0; startIndex < h; startIndex++) {
                        if (int(entryDatabase[hits[startIndex]].timestamp) >= _startTime) {
                            break;
                        }
                    }
                }
                if (_endTime == -1) {
                    endIndex = h - 1;
                } else {
                    for (endIndex = h - 1; endIndex > 0; endIndex--) {
                        if (int(entryDatabase[hits[endIndex]].timestamp) <= _endTime) {
                            break;
                        }
                    }
                }
            }

            if (startIndex < endIndex) {
                for (i = 0; i <= endIndex - startIndex; i++) {
                    // result = string.concat(result, getEntryString(hits[i]))
                    if (!init) {
                        result = getEntryString(hits[startIndex + i]);
                        init = true;
                    } else {
                        assembly {
                            mstore(0x40, add(mload(0x40), 64))
                        }
                        temp = getEntryString(hits[startIndex + i]);

                        assembly {
                            len := mload(temp)
                            dest := add(add(result, 32), mload(result))
                            src := add(temp, 32)
                            mstore(result, add(mload(result), mload(temp)))
                        }
                        for (; len >= 0; len -= 32) {
                            assembly {
                                mstore(dest, mload(src))
                            }
                            dest += 32;
                            src += 32;
                        }
                        assembly {
                            mstore(0x40, dest)
                        }
                    }
                    // end
                }
                return result;
            } else {
                if (startIndex == endIndex) {
                    result = getEntryString(hits[startIndex]);
                }
                return result;
            }
        }
    }

    // HELPER FUNCTIONS

    // given a studyID and endTime, retrieve all globalIDs that match the latest
    // entry for each patient up to that endTime for that studyID
    function getLatestIDs(uint256 _studyID, int256 _endTime) internal view returns (uint256[] memory latestIDs, int256[] memory pIDList) {
        // get unique list of patients for given study
        int256[] memory patients = study2patients[_studyID];
        uint256 h = patients.length;
        if (h == 0) {
            latestIDs = EMPTYARRAY;
            pIDList = patients;
        } else {
            uint i;
            latestIDs = new uint256[](h);
            uint256 mostRecentIndex;
            uint count;
            uint256[] storage ptr;
            unchecked {
                if (_endTime == -1) {
                    // if no endtime restriction, latest ID is patient's last ID for that study
                    for (i = 0; i < h; i++) {
                        ptr = queryMapping[int(patients[i])][int(_studyID)];
                        mostRecentIndex = ptr.length - 1;
                        latestIDs[i] = ptr[mostRecentIndex];
                    }
                    pIDList = patients;
                } else {
                    // new patient ID list to filter out the ones that don't have an entry before endtime
                    pIDList = new int256[](h);
                    for (i = 0; i < h; i++) {
                        ptr = queryMapping[int(patients[i])][int(_studyID)];
                        // if patient's first entry isn't before endtime, skip
                        if (int256(entryDatabase[ptr[0]].timestamp) <= _endTime) {
                            // if valid, then reverse linear search until we find most recent entry on or before endtime
                            for (mostRecentIndex = ptr.length - 1; mostRecentIndex > 0; mostRecentIndex--) {
                                if (int256(entryDatabase[ptr[mostRecentIndex]].timestamp) <= _endTime) {
                                    break;
                                }
                            }
                            latestIDs[count] = ptr[mostRecentIndex];
                            pIDList[count] = patients[i];
                            count++;
                        }
                    }
                    // adjusting the array size has to be done in assembly
                    assembly {
                        mstore(latestIDs, count)
                        mstore(pIDList, count)
                    }
                }
            }
        }
    }

    // perform log base 10
    // from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/Math.sol
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    // convert uint256 to string
    // from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol
    bytes16 private constant _SYMBOLS = "0123456789abcdef";

    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    function binarySearchStart(uint256[] memory array, int256 target) internal view returns (uint256) {
        uint256 low = 0;
        uint256 high = array.length;
        uint256 mid;

        unchecked {
            while (low < high) {
                mid = low + (high - low) / 2; // To avoid potential overflow

                if (int256(entryDatabase[array[mid]].timestamp) < target) {
                    low = mid + 1;
                } else {
                    high = mid;
                }
            }
        }
        return low;
    }

    function binarySearchEnd(uint256[] memory array, int256 target) internal view returns (uint256) {
        uint256 low = 0;
        uint256 high = array.length;
        uint256 mid;

        unchecked {
            while (low < high) {
                mid = low + (high - low) / 2; // To avoid potential overflow

                if (int256(entryDatabase[array[mid]].timestamp) <= target) {
                    low = mid + 1;
                } else {
                    high = mid;
                }
            }
        }
        return low - 1;
    }

    // return formatted string for one entry, for patient query
    function getEntryString(uint256 globalID) internal view returns (string memory) {
        uint256[] memory PatientCategory;
        uint256[] memory PatientElement;
        PatientCategory = catChoicesDatabase[globalID];
        PatientElement = eleChoicesDatabase[globalID];
        uint c = PatientCategory.length;
        uint e = PatientElement.length;
        bytes32 temp;

        uint dest;

        string memory entryString;

        entryString = string.concat(toString(uint256(entryDatabase[globalID].studyID)), ",", toString(entryDatabase[globalID].timestamp), ",[");

        for (uint j = 0; j < c; j++) {
            assembly {
                // memory dest = end of current entryString
                dest := add(add(entryString, 32), mload(entryString))
                // PatientCategory[j]
                mstore(0, mload(add(add(PatientCategory, 32), mul(j, 32))))
                // choicesDict[PatientCategory[j]]
                mstore(0x20, choicesDict.slot)
                // load the pointer's data
                temp := sload(keccak256(0, 0x40))

                // check if large string (32+) or small string
                switch and(temp, 0x01)
                // small string (temp is the data . length)
                case 0x00 {
                    // copy data in
                    mstore(dest, temp)
                    // get the length
                    let strlen := div(and(temp, 0xFF), 2)
                    // store the length
                    mstore(entryString, add(mload(entryString), strlen))
                }
                // large string (temp is the length*2+1)
                case 0x01 {
                    // get the length
                    let strlen := div(temp, 2)
                    // store the length
                    mstore(entryString, add(mload(entryString), strlen))
                    let i := 0
                    mstore(0, keccak256(0, 0x40))
                    // get the pointer to data
                    temp := keccak256(0, 0x20)
                    // store data 32 bytes at a time
                    for {

                    } lt(mul(i, 32), strlen) {
                        i := add(i, 1)
                    } {
                        mstore(add(dest, mul(i, 32)), sload(add(temp, i)))
                    }
                }
            }

            if (j < c - 1) {
                assembly {
                    mstore(add(add(entryString, 32), mload(entryString)), ",")
                    mstore(entryString, add(mload(entryString), 1))
                }
            }
        }

        assembly {
            mstore(add(add(entryString, 32), mload(entryString)), "],[")
            mstore(entryString, add(mload(entryString), 3))
        }

        for (uint j = 0; j < e; j++) {
            assembly {
                // memory dest = end of current entryString
                dest := add(add(entryString, 32), mload(entryString))
                // PatientElement[j]
                mstore(0, mload(add(add(PatientElement, 32), mul(j, 32))))
                // choicesDict[PatientElement[j]]
                mstore(0x20, choicesDict.slot)
                // load the pointer's data
                temp := sload(keccak256(0, 0x40))

                // check if large string (32+) or small string
                switch and(temp, 0x01)
                // small string (temp is the data . length)
                case 0x00 {
                    // copy data in
                    mstore(dest, temp)
                    // get the length
                    let strlen := div(and(temp, 0xFF), 2)
                    // store the length
                    mstore(entryString, add(mload(entryString), strlen))
                }
                // large string (temp is the length*2+1)
                case 0x01 {
                    // get the length
                    let strlen := div(temp, 2)
                    // store the length
                    mstore(entryString, add(mload(entryString), strlen))
                    let i := 0
                    mstore(0, keccak256(0, 0x40))
                    // get the pointer to data
                    temp := keccak256(0, 0x20)
                    // store data 32 bytes at a time
                    for {

                    } lt(mul(i, 32), strlen) {
                        i := add(i, 1)
                    } {
                        mstore(add(dest, mul(i, 32)), sload(add(temp, i)))
                    }
                }
            }
            if (j < e - 1) {
                assembly {
                    mstore(add(add(entryString, 32), mload(entryString)), ",")
                    mstore(entryString, add(mload(entryString), 1))
                }
            }
        }

        assembly {
            mstore(add(add(entryString, 32), mload(entryString)), "]\n")
            // why is length of "]\n" equal to 2?
            mstore(entryString, add(mload(entryString), 2))
            mstore(0x40, add(add(entryString, 32), mload(entryString)))
        }

        return entryString;
    }

    // category string to int
    function getCategoryIndex(string[] calldata _CategoryChoices) internal pure returns (uint256[] memory) {
        uint256 n = _CategoryChoices.length;
        uint256[] memory Category_index = new uint256[](n);
        for (uint256 i = 0; i < n; i++) {
            bytes memory current_string = bytes(_CategoryChoices[i]);
            Category_index[i] = uint256((uint8(current_string[0]) - 48) * 10 + (uint8(current_string[1]) - 48));
        }
        return Category_index;
    }

    // element string to int
    function getElementIndex(string[] calldata _ElementChoices) internal pure returns (uint256[] memory) {
        uint256 n = _ElementChoices.length;
        uint256[] memory Element_index = new uint256[](n);

        for (uint256 i = 0; i < n; i++) {
            bytes memory current_string = bytes(_ElementChoices[i]);
            //(uint8(current_string[1]) - 48) * 100 returns error for current_string[1]>2, very strange
            Element_index[i] = uint256(
                (uint8(current_string[0]) - 48) *
                    1000 +
                    ((uint8(current_string[1]) - 48) * 1000) /
                    10 +
                    (uint8(current_string[3]) - 48) *
                    10 +
                    (uint8(current_string[4]) - 48)
            );
        }
        return Element_index;
    }

    // Function to check if array 'a' is a subset of array 'b' assuming 'a' and 'b' are both sorted
    function isSubset(uint256[] memory a, uint256[] memory b) internal pure returns (bool) {
        uint256 aLength = a.length;
        uint256 bLength = b.length;
        unchecked {
            if (aLength > bLength) {
                return false; // If 'a' is larger than 'b', it can't be a subset
            }
            uint256 aIndex = 0;
            uint256 bIndex = 0;
            while (aIndex < aLength && bIndex < bLength) {
                if (a[aIndex] < b[bIndex]) {
                    // If an element from 'a' is smaller than the current element in 'b',
                    // it cannot exist in 'b', and 'a' is not a subset of 'b'
                    return false;
                } else if (a[aIndex] == b[bIndex]) {
                    // If the current elements are equal, move to the next element in both arrays
                    aIndex++;
                }
                bIndex++;
            }
            // If we reached the end of 'a', then all elements in 'a' have been found in 'b'
            return aIndex == aLength;
        }
    }

    function getDifference(uint256[] memory a, uint256[] memory b) internal pure returns (uint256[] memory) {
        uint256 aLength = a.length;
        uint256 bLength = b.length;
        uint256[] memory difference = new uint256[](aLength);
        uint count = 0;
        uint256 i = 0;
        uint256 j = 0;
        uint256 atemp;
        unchecked {
            while (i < aLength && j < bLength) {
                atemp = a[i];

                if (atemp < b[j]) {
                    if (count == 0 || difference[count - 1] != atemp / 100) {
                        // Add the element from 'a' to the difference array
                        difference[count] = atemp / 100;
                        count++;
                    }
                    i++;
                } else if (atemp > b[j]) {
                    j++;
                } else {
                    // Both elements are equal, move to the next element in both arrays
                    i++;
                    j++;
                }
            }
            // Add the remaining elements from 'a' to the difference array
            while (i < aLength) {
                atemp = a[i] / 100;
                if (count == 0 || difference[count - 1] != atemp) {
                    difference[count] = atemp;
                    count++;
                }
                i++;
            }
            assembly {
                mstore(difference, count)
            }
        }
        return difference;
    }

    // given a list of encoded patient/query requests/elements, return if patient matches request
    function isMatch(
        uint256[] memory PatientCategory,
        uint256[] memory RequestCategory,
        uint256[] memory PatientElement,
        uint256[] memory RequestElement
    ) internal pure returns (bool) {
        // all the inputs are lists of strings
        if (isSubset(RequestCategory, PatientCategory) == false) {
            return false;
        }
        uint256[] memory difference = getDifference(RequestElement, PatientElement);
        if (difference.length == 0) {
            return true;
        } else {
            return isSubset(difference, PatientCategory);
        }
    }
}
