// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.12;

/*
 * Team Name:
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
    mapping(uint256 => Entry) public entryDatabase;
    // globalID => choices
    mapping(uint256 => uint16[]) public catChoicesDatabase;
    mapping(uint256 => uint16[]) public eleChoicesDatabase;

    // patientID => studyID => list of globalID
    mapping(int256 => mapping(int256 => uint256[])) queryMapping;

    // choice ID => choice name
    mapping(uint16 => string) public choicesDict;
    // choice name => choice ID
    mapping(string => uint16) choicesLookup;
    // studyID => patientIDs
    mapping(uint256 => int256[]) study2patients;

    // TODO make everything that shouldn't be public not public

    constructor() {}

    function getLatestIDs2(uint256 _studyID, int256 _endTime) public view returns (uint256[] memory latestIDs, int256[] memory pIDList) {
        int256[] memory patients = study2patients[_studyID];
        uint256 h = patients.length;
        uint i;
        latestIDs = new uint256[](h);
        uint256 mostRecentIndex;
        uint count;
        uint256[] storage ptr;
        unchecked {
            if (_endTime == -1) {
                for (i = 0; i < h; i++) {
                    ptr = queryMapping[int(patients[i])][int(_studyID)];
                    mostRecentIndex = ptr.length - 1;
                    latestIDs[i] = ptr[mostRecentIndex];
                }
                assembly {
                    mstore(latestIDs, h)
                }
                pIDList = patients;
            } else {
                pIDList = new int256[](h);
                for (i = 0; i < h; i++) {
                    ptr = queryMapping[int(patients[i])][int(_studyID)];
                    if (int256(entryDatabase[ptr[0]].timestamp) <= _endTime) {
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
                assembly {
                    mstore(latestIDs, count)
                    mstore(pIDList, count)
                }
            }
        }
    }

    function getLatestIDs(uint256 _studyID, int256 _endTime) public view returns (uint256[] memory latestIDs, int256[] memory pIDList) {
        unchecked {
            uint256[] memory hits = queryMapping[-1][int(_studyID)];

            uint256 h = hits.length;
            int256 pID;
            uint256 i;
            uint256 j;

            if (h == 0) {
                return (EMPTYARRAY, pIDList);
            }

            // restrict by endtime first
            if (_endTime != -1) {
                while (int256(entryDatabase[hits[h - 1]].timestamp) > _endTime) {
                    h--;
                    if (h == 0) {
                        return (EMPTYARRAY, pIDList);
                    }
                }
            }

            // allocate memory for 2 arrays
            latestIDs = new uint256[](h);
            pIDList = new int256[](h);
            // int256[] memory pIDList;
            bool processed = false;
            uint256 patientCounter;

            for (i = h; i > 0; i--) {
                pID = entryDatabase[hits[i - 1]].patientID;
                processed = false;
                // check if added this patient already
                for (j = 0; j < pIDList.length; j++) {
                    if (pID == pIDList[j]) {
                        processed = true;
                        break;
                    }
                }

                if (!processed) {
                    patientCounter++;
                    assembly {
                        // store patient ID in list to keep track of which ones we've added
                        mstore(add(pIDList, mul(patientCounter, 32)), pID)
                        mstore(pIDList, patientCounter)

                        // store their latest globalID in return array
                        // latestIDs[patientCounter]
                        mstore(add(latestIDs, mul(patientCounter, 32)), mload(add(hits, mul(i, 0x20))))
                    }
                }
            }
            if (patientCounter == 0) {
                return (EMPTYARRAY, pIDList);
            }
            assembly {
                mstore(latestIDs, patientCounter)
            }
            return (latestIDs, pIDList);
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

    function toString(uint256 value) public pure returns (string memory) {
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
        uint16 ce;

        unchecked {
            for (uint256 i = 0; i < c; i++) {
                b = bytes(_patientCategoryChoices[i]);
                // convert category/element string to int: ex "11_05" becomes 1105
                ce = uint16((uint8(b[0]) - 48) * 10 + (uint8(b[1]) - 48));
                // store it
                catChoicesDatabase[gCounter].push(ce);
                // if we haven't seen this category/element yet
                if (keccak256(bytes(choicesDict[ce])) == EMPTYSTRING) {
                    // keep track of what the string was
                    choicesDict[ce] = _patientCategoryChoices[i];
                    choicesLookup[_patientCategoryChoices[i]] = ce;
                }
            }

            for (uint256 i = 0; i < e; i++) {
                b = bytes(_patientElementChoices[i]);
                ce = uint16((uint8(b[0]) - 48) * 1000 + (uint16((uint8(b[1]) - 48)) * 1000) / 10 + (uint8(b[3]) - 48) * 10 + (uint8(b[4]) - 48));

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
                study2patients[_studyID].push(int(_patientID));
            }

            // For all possible queries of patient ID and study ID, append globalID to querymap
            queryMapping[iPatientID][iStudyID].push(gCounter);
            queryMapping[-1][iStudyID].push(gCounter);
            queryMapping[iPatientID][-1].push(gCounter);
            // queryMapping[-1][-1].push(gCounter);
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
            (LatestIDs, pIDList) = getLatestIDs2(_studyID, _endTime);
            uint256 h = LatestIDs.length;
            if (h == 0) {
                return EMPTYARRAY;
            }
            uint256 resultCounter;
            int256 pID;
            result = new uint256[](LatestIDs.length);

            uint16[] memory RequestCategory = getCategoryIndex(_requestedCategoryChoices);
            uint16[] memory RequestElement = getElementIndex(_requestedElementChoices);

            uint16[] memory PatientCategory;
            uint16[] memory PatientElement;
            for (uint256 i = 0; i < h; i++) {
                PatientCategory = catChoicesDatabase[LatestIDs[i]];
                PatientElement = eleChoicesDatabase[LatestIDs[i]];
                if (isMatchSimple(PatientCategory, RequestCategory, PatientElement, RequestElement)) {
                    resultCounter++;
                    pID = pIDList[i];
                    assembly {
                        mstore(add(result, mul(resultCounter, 32)), pID)
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

    function binarySearchStart(uint256[] memory array, int256 target) public view returns (uint256) {
        uint256 low = 0;
        uint256 high = array.length;
        unchecked {
            while (low < high) {
                uint256 mid = low + (high - low) / 2; // To avoid potential overflow

                if (int256(entryDatabase[array[mid]].timestamp) < target) {
                    low = mid + 1;
                } else {
                    high = mid;
                }
            }
        }
        return low;
    }

    function binarySearchEnd(uint256[] memory array, int256 target) public view returns (uint256) {
        uint256 low = 0;
        uint256 high = array.length;

        unchecked {
            while (low < high) {
                uint256 mid = low + (high - low) / 2; // To avoid potential overflow

                if (int256(entryDatabase[array[mid]].timestamp) <= target) {
                    low = mid + 1;
                } else {
                    high = mid;
                }
            }
        }
        return low - 1;
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
            if (h == 0 || _startTime > int(entryDatabase[hits[h - 1]].timestamp) || _endTime < int(entryDatabase[hits[0]].timestamp)) {
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
                    // linear search start
                    for (startIndex = 0; startIndex < h; startIndex++) {
                        if (int(entryDatabase[hits[startIndex]].timestamp) >= _startTime) {
                            break;
                        }
                    }
                }
                if (_endTime == -1) {
                    endIndex = h - 1;
                } else {
                    // linear search end
                    for (endIndex = h - 1; endIndex > 0; endIndex--) {
                        if (int(entryDatabase[hits[endIndex]].timestamp) <= _endTime) {
                            break;
                        }
                    }
                }
            }

            if (startIndex < endIndex) {
                for (i = 0; i <= endIndex - startIndex; i++) {
                    // result = string.concat(result, getEntryStringA(hits[i]))
                    if (!init) {
                        result = getEntryStringA(hits[i]);
                        init = true;
                    } else {
                        assembly {
                            mstore(0x40, add(mload(0x40), 64))
                        }
                        temp = getEntryStringA(hits[i]);

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
                    result = getEntryStringA(hits[startIndex]);
                }
                return result;
            }
        }
    }

    function getEntryStringA(uint256 globalID) public view returns (string memory) {
        uint16[] memory PatientCategory;
        uint16[] memory PatientElement;
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

    function getCategoryIndex(string[] memory _CategoryChoices) public pure returns (uint16[] memory) {
        uint256 n = _CategoryChoices.length;
        uint16[] memory Category_index = new uint16[](n);
        for (uint256 i = 0; i < n; i++) {
            bytes memory current_string = bytes(_CategoryChoices[i]);
            Category_index[i] = uint16((uint8(current_string[0]) - 48) * 10 + (uint8(current_string[1]) - 48));
        }
        return Category_index;
    }

    function getElementIndex(string[] memory _ElementChoices) public pure returns (uint16[] memory) {
        uint256 n = _ElementChoices.length;
        uint16[] memory Element_index = new uint16[](n);

        for (uint256 i = 0; i < n; i++) {
            bytes memory current_string = bytes(_ElementChoices[i]);
            //(uint8(current_string[1]) - 48) * 100 returns error for current_string[1]>2, very strange
            Element_index[i] = uint16(
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
    function isSubset(uint16[] memory a, uint16[] memory b) public pure returns (bool) {
        uint256 aLength = a.length;
        uint256 bLength = b.length;
        unchecked {
            if (aLength > bLength) {
                return false; // If 'a' is larger than 'b', it can't be a subset
            }
            uint256 aIndex = 0;
            uint256 bIndex = 0;
            while (aIndex < a.length && bIndex < b.length) {
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
            return aIndex == a.length;
        }
    }

    function getDifference(uint16[] memory a, uint16[] memory b) public pure returns (uint16[] memory) {
        uint256 aLength = a.length;
        uint256 bLength = b.length;
        uint16[] memory difference = new uint16[](a.length);
        uint count = 0;
        uint256 i = 0;
        uint256 j = 0;
        uint16 atemp;
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

    function isMatchSimple(
        uint16[] memory PatientCategory,
        uint16[] memory RequestCategory,
        uint16[] memory PatientElement,
        uint16[] memory RequestElement
    ) public pure returns (bool) {
        // all the inputs are lists of strings
        if (isSubset(RequestCategory, PatientCategory) == false) {
            return false;
        }
        uint16[] memory difference = getDifference(RequestElement, PatientElement);
        if (difference.length == 0) {
            return true;
        } else {
            return isSubset(difference, PatientCategory);
        }
    }
}
