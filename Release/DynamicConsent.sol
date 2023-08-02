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
    int256 private constant WILDCARD = -1;

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
    function storeRecord(uint256 _patientID, uint256 _studyID, uint256 _recordTime, string[] calldata _patientCategoryChoices, string[] calldata _patientElementChoices) public {
        /*
            Your code here.
        */
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
    function queryForResearcher(uint256 _studyID, int256 _endTime, string[] calldata _requestedCategoryChoices, string[] calldata _requestedElementChoices) public view returns(uint256[] memory) {
        /*
            Your code here.
        */
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
    function queryForPatient(uint256 _patientID, int256 _studyID, int256 _startTime, int256 _endTime) public view returns(string memory) {
        /*
            Your code here.
        */
    }
}
