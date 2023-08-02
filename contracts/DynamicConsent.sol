// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.12;

/**
 * Team Name:
 *
 *   Team Member 1:
 *       { Name: , Email:  }
 *   Team Member 2:
 *       { Name: , Email:  }
 *   Team Member 3:
 *       { Name: , Email:  }
 *	...
 *   Team Member n:
 *       { Name: , Email:  }
 *
 * Declaration of cross-team collaboration:
 *	We DO/DO NOT collaborate with (list teams).
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
    mapping(uint256 => uint16[]) public choicesDatabase;

    // patientID => studyID => list of globalID
    mapping(int256 => mapping(int256 => uint256[])) queryMapping;
    // string => encoded string
    //mapping(string => mapping(string => uint104)) encodeString;
    // mapping(uint16 => mapping(uint16 => uint104)) encodeString;

    // encoded string => string
    //mapping(uint256 => string) decodeString;
    // globalID => output string
    mapping(uint256 => string) toEntryString;

    // choice ID => encoded choice
    mapping(uint16 => uint256) public elementsMapping;
    // choice ID => choice name
    mapping(uint16 => string) public choicesDict;
    // choice name => choice ID
    mapping(string => uint16) choicesLookup;

    // TODO make everything that shouldn't be public not public

    constructor() {
        // for (uint256 i = 1; i< 10; i++){
        //     for (uint256 j = 1; j< 100; j++){
        //         encodeString[toString2(i)][toString2(j)] = uint104(1 << j-1);
        //     }
        //     encodeString[toString2(i)]["*"] = uint104((1<<104)-1);
        // }
        // for (uint16 i = 1; i< 10; i++){
        //     for (uint16 j = 1; j< 10; j++){
        //         encodeString[i][j] = uint104(1 << j-1);
        //     }
        //     encodeString[i][255] = uint104((1<<104)-1);
        // }
    }

    function testA(uint256 A) public pure returns (bytes memory) {
        bytes memory result;
        assembly {
            result := 1000
            mstore(result, 32)
            mstore(add(result, 32), A)
        }
        return result;
    }

    function testD(string memory s) public view returns (uint256) {
        bytes memory b = bytes(s);
        uint16 m = uint16(
            (uint8(b[0]) - 48) *
                1000 +
                (uint8(b[1]) - 48) *
                100 +
                (uint8(b[3]) - 48) *
                10 +
                (uint8(b[4]) - 48)
        );
        return elementsMapping[m];
    }

    function testE(
        string memory s
    ) public pure returns (string memory, string memory) {
        bytes memory b = bytes(s);

        string memory A = string(abi.encodePacked(b[0], b[1]));
        string memory B = string(abi.encodePacked(b[3], b[4]));

        return (A, B);
    }

    function testC(
        uint256 A,
        uint256 B
    ) public pure returns (uint256[] memory) {
        uint256[] memory result;

        assembly {
            result := add(mload(0x40), 512)
            //mstore(0x40, add(result,add(0x20,mul(10,0x20))))
            mstore(result, 2)
            mstore(add(result, 32), A)
            mstore(add(result, 64), B)
        }
        return result;
    }

    function testG(uint256 A) public pure returns (uint256) {
        uint256[] memory latestIDs = new uint256[](10);
        assembly {
            mstore(latestIDs, A)
        }
        return latestIDs.length;
    }

    function testB(
        string[] calldata _patientElementChoices
    ) public returns (uint256) {
        uint256 e = _patientElementChoices.length;
        bytes memory b;
        uint16 ce;

        for (uint256 i = 0; i < e; i++) {
            b = bytes(_patientElementChoices[i]);
            ce = uint16(
                (uint8(b[0]) - 48) *
                    1000 +
                    (uint8(b[3]) - 48) *
                    10 +
                    (uint8(b[4]) - 48)
            );
            uint16 temp = uint16((uint8(b[1]) - 48));
            temp *= 100;
            ce += temp; // need to seperate this out or a bug happens (no idea why)

            // if we haven't seen this category/element yet
            if (keccak256(bytes(choicesDict[ce])) == EMPTYSTRING) {
                // keep track of what the string was
                choicesDict[ce] = _patientElementChoices[i];
                // add it to element mapping
                elementsMapping[ce] = 1 << eCounter;
                // keep track of category=>elements in the same mapping
                elementsMapping[ce / 100] |= 1 << eCounter;
                // TODO what happens when eCounter > 256 ... maybe a list of uint256 instead???
                eCounter++;
            }
        }
        return 1;
    }

    function getLatestIDs(
        uint256 _studyID,
        int256 _endTime
    ) public view returns (uint256[] memory latestIDs) {
        unchecked {
            uint256[] memory hits = queryMapping[-1][int(_studyID)];

            uint256 h = hits.length;
            int256 pID;
            uint256 latestGID;
            uint256 i;
            uint256 j;

            if (h == 0) {
                return EMPTYARRAY;
            }

            // restrict by endtime first
            if (_endTime != -1) {
                while (
                    int256(entryDatabase[hits[h - 1]].timestamp) > _endTime
                ) {
                    h--;
                    if (h == 0) {
                        return EMPTYARRAY;
                    }
                }
            }

            // allocate memory for 2 arrays
            latestIDs = new uint256[](h);
            int256[] memory pIDList;
            bool processed = false;
            uint256 patientCounter;
            assembly {
                pIDList := add(mload(0x40), 32)
                // be careful we do not allocate more memory after this point!
            }

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
                    latestGID = hits[i - 1];
                    assembly {
                        // store patient ID in list to keep track of which ones we've added
                        mstore(pIDList, patientCounter)
                        mstore(add(pIDList, mul(patientCounter, 32)), pID)
                        // do we need to update free memory pointer?
                        // mstore(0x40, add(pIDList,add(0x20,mul(patientCounter,0x20))))

                        // store their latest globalID in return array
                        mstore(latestIDs, patientCounter)
                        // latestIDs[patientCounter]
                        mstore(
                            add(latestIDs, mul(patientCounter, 32)),
                            mload(add(hits, mul(i, 0x20)))
                        )
                    }
                }
            }
            if (patientCounter == 0) {
                return EMPTYARRAY;
            }
        }
        return latestIDs;
    }

    // function encode(string[] memory CategoryChoices, string[] memory ElementChoices) public view returns(uint256) {
    //     uint256 c = CategoryChoices.length;
    //     uint256 e = ElementChoices.length;
    //     uint256 result;

    //     unchecked{
    //         for (uint256 i = 0; i < c;i++){
    //             result |= encodeString[CategoryChoices[i]];
    //         }

    //         for (uint256 i = 0; i < e;i++){
    //             result |= encodeString[ElementChoices[i]];
    //         }
    //     }
    //     return result;
    // }

    function encodePatient(uint256 globalID) public view returns (uint256) {
        uint256 result;
        uint16[] memory choices = choicesDatabase[globalID];

        uint256 c = choices.length;

        unchecked {
            for (uint256 i = 0; i < c; i++) {
                result |= elementsMapping[choices[i]];
            }
        }

        return result;
    }

    function isMatch(
        uint256 patientPrefs,
        uint256 queryPrefs
    ) public pure returns (bool) {
        // see https://en.wikipedia.org/wiki/Material_conditional
        return
            (type(uint256).max ^ queryPrefs ^ (queryPrefs & patientPrefs)) ==
            type(uint256).max;
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

    // // convert 2-digit uint256 to string, with leading 0 if needed
    // // based on https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Strings.sol
    // function toString2(uint256 value) public pure returns (string memory) {
    //     unchecked{
    //         string memory result = new string(2);
    //         assembly{
    //             mstore8(add(result, 33), byte(mod(value, 10), _SYMBOLS))
    //             mstore8(add(result, 32), byte(mod(div(value,10), 10), _SYMBOLS))
    //         }
    //         return result;
    //     }
    // }

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
        entryDatabase[gCounter].patientID = int(_patientID);
        entryDatabase[gCounter].studyID = int(_studyID);
        entryDatabase[gCounter].timestamp = _recordTime;
        //entryDatabase[gCounter].SharingChoices = encode(_patientCategoryChoices, _patientElementChoices);

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
                choicesDatabase[gCounter].push(ce);
                // if we haven't seen this category/element yet
                if (keccak256(bytes(choicesDict[ce])) == EMPTYSTRING) {
                    // keep track of what the string was
                    choicesDict[ce] = _patientCategoryChoices[i];
                    choicesLookup[_patientCategoryChoices[i]] = ce;
                }
            }

            for (uint256 i = 0; i < e; i++) {
                b = bytes(_patientElementChoices[i]);
                ce = uint16(
                    (uint8(b[0]) - 48) *
                        1000 +
                        (uint8(b[3]) - 48) *
                        10 +
                        (uint8(b[4]) - 48)
                );
                uint16 temp = uint16((uint8(b[1]) - 48));
                temp *= 100;
                ce += temp; // STILL no idea why this bug happens

                choicesDatabase[gCounter].push(ce);
                // if we haven't seen this category/element yet
                if (keccak256(bytes(choicesDict[ce])) == EMPTYSTRING) {
                    // keep track of what the string was
                    choicesDict[ce] = _patientElementChoices[i];
                    choicesLookup[_patientElementChoices[i]] = ce;
                    // add it to element mapping
                    elementsMapping[ce] = 1 << eCounter;
                    // keep track of category=>elements in the same mapping
                    elementsMapping[ce / 100] |= 1 << eCounter;
                    // TODO what happens when eCounter > 256 ... maybe a list of uint256 instead???
                    eCounter++;
                }
            }

            // create entryString
            // assembly version is better
            string memory entryString = string.concat(
                toString(_studyID),
                ",",
                toString(_recordTime),
                ",["
            );

            for (uint256 i = 0; i < c; i++) {
                entryString = string.concat(
                    entryString,
                    _patientCategoryChoices[i]
                );
                if (i < c - 1) {
                    entryString = string.concat(entryString, ",");
                }
            }
            entryString = string.concat(entryString, "],[");
            for (uint256 i = 0; i < e; i++) {
                entryString = string.concat(
                    entryString,
                    _patientElementChoices[i]
                );
                if (i < e - 1) {
                    entryString = string.concat(entryString, ",");
                }
            }
            entryString = string.concat(entryString, "]\n");
            toEntryString[gCounter] = entryString;

            // For all possible queries of patient ID and study ID, append globalID to querymap
            // can patient ID be -1?
            queryMapping[int(_patientID)][int(_studyID)].push(gCounter);
            queryMapping[-1][int(_studyID)].push(gCounter);
            queryMapping[int(_patientID)][-1].push(gCounter);
            queryMapping[-1][-1].push(gCounter);
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
        uint256 c = _requestedCategoryChoices.length;
        uint256 e = _requestedElementChoices.length;
        uint256 encodeQuery;
        uint16 temp;
        uint256 i;
        unchecked {
            for (i = 0; i < c; i++) {
                temp = choicesLookup[_requestedCategoryChoices[i]];
                if (temp != 0) {
                    encodeQuery |= elementsMapping[temp];
                } else {
                    // if looking up a category that doesnt exist, result is always empty since no patient has it
                    return EMPTYARRAY;
                }
            }

            for (i = 0; i < e; i++) {
                temp = choicesLookup[_requestedElementChoices[i]];
                if (temp != 0) {
                    encodeQuery |= elementsMapping[temp];
                } // TODO: if element doesn't exist, we need to do a manual search
            }

            uint256[] memory LatestIDs = getLatestIDs(_studyID, _endTime);
            uint256 h = LatestIDs.length;
            if (h == 0) {
                return EMPTYARRAY;
            }
            uint256 resultCounter;
            int256 pID;

            assembly {
                result := add(mload(0x40), 32)
                // be careful we do not allocate more memory after this point!
            }

            for (i = 0; i < h; i++) {
                if (isMatch(encodePatient(LatestIDs[i]), encodeQuery)) {
                    resultCounter++;
                    pID = entryDatabase[LatestIDs[i]].patientID;
                    assembly {
                        mstore(result, resultCounter)
                        mstore(add(result, mul(resultCounter, 32)), pID)
                    }
                }
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
    function queryForPatient(
        uint256 _patientID,
        int256 _studyID,
        int256 _startTime,
        int256 _endTime
    ) public view returns (string memory) {
        uint256[] memory hits = queryMapping[int(_patientID)][_studyID];
        uint256 h = hits.length;
        string memory result;
        if (h == 0) {
            return result;
        }
        unchecked {
            for (uint256 i = 0; i < h; i++) {
                // if hit is valid
                Entry memory entry = entryDatabase[hits[i]];
                if (
                    (_startTime == -1 || uint(_startTime) <= entry.timestamp) &&
                    (_endTime == -1 || uint(_endTime) >= entry.timestamp)
                ) {
                    result = string.concat(result, toEntryString[hits[i]]);
                }
            }
        }
        return result;
    }

    function getCategoryIndex(
        string[] calldata _CategoryChoices
    ) public pure returns (uint256[] memory) {
        uint256 n = _CategoryChoices.length;
        uint256[] memory Category_index = new uint256[](n);
        for (uint256 i = 0; i < n; i++) {
            bytes memory current_string = bytes(_CategoryChoices[i]);
            Category_index[i] = uint16(
                (uint8(current_string[0]) - 48) *
                    10 +
                    (uint8(current_string[1]) - 48)
            );
        }
        return Category_index;
    }

    function getElementIndex(
        string[] calldata _ElementChoices
    ) public pure returns (uint256[] memory) {
        uint256 n = _ElementChoices.length;
        uint256[] memory Element_index = new uint256[](n);

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
    function isSubset(
        uint256[] memory a,
        uint256[] memory b
    ) public pure returns (bool) {
        uint256 aLength = a.length;
        uint256 bLength = b.length;
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

    function getDifference(
        uint256[] memory a,
        uint256[] memory b
    ) public pure returns (uint256[] memory) {
        uint256 aLength = a.length;
        uint256 bLength = b.length;
        uint[] memory difference = new uint[](a.length);
        uint count = 0;
        uint256 i = 0;
        uint256 j = 0;
        while (i < aLength && j < bLength) {
            if (a[i] < b[j]) {
                // Add the element from 'a' to the difference array
                difference[count] = a[i];
                i++;
                count++;
            } else if (a[i] > b[j]) {
                j++;
            } else {
                // Both elements are equal, move to the next element in both arrays
                i++;
                j++;
            }
        }
        // Add the remaining elements from 'a' to the difference array
        while (i < aLength) {
            difference[count] = a[i];
            i++;
            count++;
        }
        uint[] memory result = new uint[](count);
        for (uint k = 0; k < count; k++) {
            //return only the category information of the differentce
            result[k] = uint(difference[k] / 100);
        }
        return result;
    }

    function isMatchSimple(
        string[] calldata _patientCategoryChoices,
        string[] calldata _patientElementChoices,
        string[] calldata _requestedCategoryChoices,
        string[] calldata _requestedElementChoices
    ) public pure returns (bool) {
        // all the inputs are lists of strings
        uint256[] memory PatientCategory = getCategoryIndex(
            _patientCategoryChoices
        );
        uint256[] memory RequestCategory = getCategoryIndex(
            _requestedCategoryChoices
        );
        if (isSubset(RequestCategory, PatientCategory) == false) {
            return false;
        }
        uint256[] memory PatientElement = getElementIndex(
            _patientElementChoices
        );
        uint256[] memory RequestElement = getElementIndex(
            _requestedElementChoices
        );
        uint256[] memory difference = getDifference(
            RequestElement,
            PatientElement
        );
        if (difference.length == 0) {
            return true;
        } else {
            return isSubset(difference, PatientCategory);
        }
    }
}
