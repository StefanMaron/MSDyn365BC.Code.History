table 1252 "Bank Pmt. Appl. Rule"
{
    Caption = 'Bank Pmt. Appl. Rule';

    fields
    {
        field(1; "Match Confidence"; Option)
        {
            Caption = 'Match Confidence';
            OptionCaption = 'None,Low,Medium,High';
            OptionMembers = "None",Low,Medium,High;
        }
        field(2; Priority; Integer)
        {
            Caption = 'Priority';

            trigger OnValidate()
            begin
                if (Priority > GetMaximumPriorityNo) or (Priority < 1) then
                    Error(WrongPriorityNoErr, FieldCaption(Priority), 1, GetMaximumPriorityNo);
            end;
        }
        field(3; "Related Party Matched"; Option)
        {
            Caption = 'Related Party Matched';
            OptionCaption = 'Not Considered,Fully,Partially,No';
            OptionMembers = "Not Considered",Fully,Partially,No;
        }
        field(4; "Doc. No./Ext. Doc. No. Matched"; Option)
        {
            Caption = 'Doc. No./Ext. Doc. No. Matched';
            OptionCaption = 'Not Considered,Yes,No,Yes - Multiple';
            OptionMembers = "Not Considered",Yes,No,"Yes - Multiple";
        }
        field(5; "Amount Incl. Tolerance Matched"; Option)
        {
            Caption = 'Amount Incl. Tolerance Matched';
            OptionCaption = 'Not Considered,One Match,Multiple Matches,No Matches';
            OptionMembers = "Not Considered","One Match","Multiple Matches","No Matches";
        }
        field(6; "Direct Debit Collect. Matched"; Option)
        {
            Caption = 'Direct Debit Collect. Matched';
            OptionCaption = 'Not Considered,Yes,No';
            OptionMembers = "Not Considered",Yes,No;
        }
        field(30; Score; Integer)
        {
            Caption = 'Score';
            Editable = false;
        }

        field(40; "Review Required"; Boolean)
        {
            Caption = 'Review Required';
        }

        field(41; "Apply Immediatelly"; Boolean)
        {
            Caption = 'Apply Immediatelly';
        }

        field(11700; "Bank Pmt. Appl. Rule Code"; Code[10])
        {
            Caption = 'Bank Pmt. Appl. Rule Code';
#if not CLEAN19
            TableRelation = "Bank Pmt. Appl. Rule Code";
#endif
            ObsoleteState = Pending;
            ObsoleteReason = 'Moved to Banking Documents Localization for Czech.';
            ObsoleteTag = '19.0';
        }

        field(11705; "Variable Symbol Matched"; Option)
        {
            Caption = 'Variable Symbol Matched';
            OptionCaption = 'Not Considered,Yes,No,Yes - Multiple';
            OptionMembers = "Not Considered",Yes,No,"Yes - Multiple";
#if not CLEAN19
            ObsoleteState = Pending;
#else
            ObsoleteState = Removed;
#endif
            ObsoleteReason = 'Moved to Banking Documents Localization for Czech.';
            ObsoleteTag = '19.0';
        }
        field(11706; "Specific Symbol Matched"; Option)
        {
            Caption = 'Specific Symbol Matched';
            OptionCaption = 'Not Considered,Yes,No,Yes - Multiple';
            OptionMembers = "Not Considered",Yes,No,"Yes - Multiple";
#if not CLEAN19
            ObsoleteState = Pending;
#else
            ObsoleteState = Removed;
#endif
            ObsoleteReason = 'Moved to Banking Documents Localization for Czech.';
            ObsoleteTag = '19.0';
        }
        field(11707; "Constant Symbol Matched"; Option)
        {
            Caption = 'Constant Symbol Matched';
            OptionCaption = 'Not Considered,Yes,No,Yes - Multiple';
            OptionMembers = "Not Considered",Yes,No,"Yes - Multiple";
#if not CLEAN19
            ObsoleteState = Pending;
#else
            ObsoleteState = Removed;
#endif
            ObsoleteReason = 'Moved to Banking Documents Localization for Czech.';
            ObsoleteTag = '19.0';
        }
        field(11710; "Bank Transaction Type"; Option)
        {
            Caption = 'Bank Transaction Type';
            OptionCaption = 'Both,+,-';
            OptionMembers = Both,"+","-";
#if not CLEAN19
            ObsoleteState = Pending;
#else
            ObsoleteState = Removed;
#endif
            ObsoleteReason = 'Moved to Banking Documents Localization for Czech.';
            ObsoleteTag = '19.0';
        }
    }

    keys
    {
        key(Key1; "Bank Pmt. Appl. Rule Code", "Match Confidence", Priority)
        {
            Clustered = true;
            ObsoleteState = Pending;
            ObsoleteReason = 'Merge to W1.';
            ObsoleteTag = '19.0';
        }
        key(Key2; Score)
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        Validate(Priority);
        UpdateScore(Rec);
    end;

    trigger OnRename()
    begin
        UpdateScore(Rec);
    end;

    var
        WrongPriorityNoErr: Label 'The %1 you entered is invalid. The %1 must be between %2 and %3.', Comment = '%1 - Table field with caption Priority. %2 and %3 are numbers presenting a range - e.g. 1 and 999';
        LoadRulesOnlyOnTempRecordsErr: Label 'Programming error: The LoadRules function can only be called from temporary records.', Comment = 'Description to developers, should not be seen by users';

#if CLEAN19
    procedure LoadRules()
#else
    [Obsolete('Merge to W1.', '19.0')]
    procedure LoadRules(BankPmtApplRuleCode: Code[10])
#endif
    var
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
    begin
        if not IsTemporary then
            Error(LoadRulesOnlyOnTempRecordsErr);

        DeleteAll();
#if CLEAN19
        BankPmtApplRule.SetRange("Bank Pmt. Appl. Rule Code", ''); // NAVCZ
#else
        BankPmtApplRule.SetRange("Bank Pmt. Appl. Rule Code", BankPmtApplRuleCode); // NAVCZ
#endif
        if BankPmtApplRule.FindSet then
            repeat
                TransferFields(BankPmtApplRule);
                Insert;
            until BankPmtApplRule.Next() = 0;
    end;

    procedure GetBestMatchScore(ParameterBankPmtApplRule: Record "Bank Pmt. Appl. Rule"): Integer
    begin
        Clear(Rec);
        SetCurrentKey(Score);
        Ascending(false);

        SetFilter("Related Party Matched", '%1|%2',
          ParameterBankPmtApplRule."Related Party Matched",
          ParameterBankPmtApplRule."Related Party Matched"::"Not Considered");

        SetFilter("Doc. No./Ext. Doc. No. Matched", '%1|%2',
          ParameterBankPmtApplRule."Doc. No./Ext. Doc. No. Matched",
          ParameterBankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Not Considered");

        SetFilter("Amount Incl. Tolerance Matched", '%1|%2',
          ParameterBankPmtApplRule."Amount Incl. Tolerance Matched",
          ParameterBankPmtApplRule."Amount Incl. Tolerance Matched"::"Not Considered");

        SetFilter("Direct Debit Collect. Matched", '%1|%2',
          ParameterBankPmtApplRule."Direct Debit Collect. Matched",
          ParameterBankPmtApplRule."Direct Debit Collect. Matched"::"Not Considered");

#if not CLEAN19
        // NAVCZ
        SetFilter("Variable Symbol Matched", '%1|%2',
          ParameterBankPmtApplRule."Variable Symbol Matched",
          ParameterBankPmtApplRule."Variable Symbol Matched"::"Not Considered");

        SetFilter("Specific Symbol Matched", '%1|%2',
          ParameterBankPmtApplRule."Specific Symbol Matched",
          ParameterBankPmtApplRule."Specific Symbol Matched"::"Not Considered");

        SetFilter("Constant Symbol Matched", '%1|%2',
          ParameterBankPmtApplRule."Constant Symbol Matched",
          ParameterBankPmtApplRule."Constant Symbol Matched"::"Not Considered");

        SetFilter("Bank Transaction Type", '%1|%2',
          ParameterBankPmtApplRule."Bank Transaction Type",
          ParameterBankPmtApplRule."Bank Transaction Type"::Both);
        // NAVCZ

#endif
        if FindFirst then
            exit(Score);

        exit(0);
    end;

    procedure GetReviewRequiredScoreFilter(): Text
    var
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        SelectionFilterManagement: Codeunit SelectionFilterManagement;
        BankPmtRecordRef: RecordRef;
    begin
        BankPmtApplRule.SetRange("Review Required", true);
        BankPmtApplRule.SetCurrentKey(Score);
        BankPmtRecordRef.GetTable(BankPmtApplRule);
        exit(SelectionFilterManagement.GetSelectionFilter(BankPmtRecordRef, BankPmtApplRule.FieldNo(Score)));
    end;

    procedure IsMatchedAutomatically(MatchConfidence: Option; NoOfAppliedEntries: Integer): Boolean
    begin
        if (NoOfAppliedEntries = 0) then
            exit(false);

        exit(MatchConfidence in ["Match Confidence"::None, "Match Confidence"::Low, "Match Confidence"::Medium, "Match Confidence"::High]);
    end;

    [Obsolete('Replaced by BankAccReconciliationLine.GetMatchedAutomaticallyFilter()', '18.0')]
    procedure GetMatchedAutomaticallyFilter(): Text
    begin
        exit(StrSubstNo('=%1|%2|%3|%4', "Match Confidence"::None, "Match Confidence"::Low, "Match Confidence"::Medium, "Match Confidence"::High));
    end;

    procedure GetTextMapperScore(): Integer
    var
        MediumConfidenceHighestScore: Integer;
    begin
        // Text mapper should override only Medium confidence and lower
#if CLEAN19
        MediumConfidenceHighestScore := CalculateScore("Match Confidence"::Medium, 0);
#else
        MediumConfidenceHighestScore := CalculateScore("Match Confidence"::Medium, Priority); // NAVCZ
#endif
        exit(MediumConfidenceHighestScore);
    end;

    local procedure UpdateScore(var BankPmtApplRule: Record "Bank Pmt. Appl. Rule")
    begin
        BankPmtApplRule.Score := CalculateScore(BankPmtApplRule."Match Confidence", BankPmtApplRule.Priority);
    end;

    local procedure CalculateScore(MatchConfidence: Option; NewPriority: Integer): Integer
    var
        ConfidenceRangeScore: Integer;
    begin
        ConfidenceRangeScore := (MatchConfidence + 1) * GetConfidenceScoreRange;

        // Update the score based on priority
        exit(ConfidenceRangeScore - NewPriority);
    end;

    local procedure GetConfidenceScoreRange(): Integer
    begin
        exit(1000);
    end;

    local procedure GetMaximumPriorityNo(): Integer
    begin
        exit(GetConfidenceScoreRange - 1);
    end;

#if CLEAN19
    procedure GetMatchConfidence(MatchQuality: Integer): Integer
#else
    [Obsolete('Merge to W1.', '19.0')]
    procedure GetMatchConfidence(MatchQuality: Integer; IsTextMapper: Boolean): Integer
#endif
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        OptionNo: Integer;
    begin
#if CLEAN19
        if MatchQuality = GetTextMapperScore then
#else
        if IsTextMapper then // NAVCZ
#endif
            exit(BankAccReconciliationLine."Match Confidence"::"High - Text-to-Account Mapping");

        OptionNo := MatchQuality div GetConfidenceScoreRange;
        case OptionNo of
            "Match Confidence"::None:
                exit(BankAccReconciliationLine."Match Confidence"::None);
            "Match Confidence"::Low:
                exit(BankAccReconciliationLine."Match Confidence"::Low);
            "Match Confidence"::Medium:
                exit(BankAccReconciliationLine."Match Confidence"::Medium);
            "Match Confidence"::High:
                exit(BankAccReconciliationLine."Match Confidence"::High);
        end;
    end;

    procedure GetLowestScoreInRange(AssignedScore: Integer): Integer
    begin
        exit((AssignedScore div GetConfidenceScoreRange) * GetConfidenceScoreRange);
    end;

    procedure GetHighestScoreInRange(AssignedScore: Integer): Integer
    begin
        exit(GetLowestScoreInRange(AssignedScore) + GetConfidenceScoreRange);
    end;

    procedure GetHighestPossibleScore(): Integer
    begin
        exit(GetConfidenceScoreRange * ("Match Confidence"::High + 1));
    end;

    procedure InsertDefaultMatchingRules()
    var
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
        RulePriority: Integer;
    begin
#if CLEAN19
        BankPmtApplRule.SetRange("Bank Pmt. Appl. Rule Code", ''); // NAVCZ
#else
        BankPmtApplRule.SetRange("Bank Pmt. Appl. Rule Code", "Bank Pmt. Appl. Rule Code"); // NAVCZ
#endif
        if not BankPmtApplRule.IsEmpty() then
            exit;

        // Insert High Confidence rules
        RulePriority := 1;
        InsertBankPaymentApplicationRule(
          BankPmtApplRule."Match Confidence"::High, RulePriority,
          BankPmtApplRule."Related Party Matched"::"Not Considered",
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Not Considered",
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"Not Considered",
          BankPmtApplRule."Direct Debit Collect. Matched"::Yes,
#if CLEAN19
          true);
#else
          true,
          // NAVCZ
          BankPmtApplRule."Variable Symbol Matched"::"Not Considered",
          BankPmtApplRule."Specific Symbol Matched"::"Not Considered",
          BankPmtApplRule."Constant Symbol Matched"::"Not Considered",
          BankPmtApplRule."Bank Transaction Type"::Both);
        // NAVCZ;
#endif

        InsertBankPaymentApplicationRule(
          BankPmtApplRule."Match Confidence"::High, RulePriority,
          BankPmtApplRule."Related Party Matched"::Fully,
#if CLEAN19
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Yes - Multiple",
#else
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Not Considered", // NAVCZ
#endif
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"One Match",
          BankPmtApplRule."Direct Debit Collect. Matched"::"Not Considered",
#if CLEAN19
          true);
#else
          true,
          // NAVCZ
          BankPmtApplRule."Variable Symbol Matched"::"Yes - Multiple",
          BankPmtApplRule."Specific Symbol Matched"::"Not Considered",
          BankPmtApplRule."Constant Symbol Matched"::"Not Considered",
          BankPmtApplRule."Bank Transaction Type"::Both);
        // NAVCZ
#endif

        InsertBankPaymentApplicationRule(
          BankPmtApplRule."Match Confidence"::High, RulePriority,
          BankPmtApplRule."Related Party Matched"::Fully,
#if CLEAN19
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Yes - Multiple",
#else
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Not Considered", // NAVCZ
#endif
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"Multiple Matches",
          BankPmtApplRule."Direct Debit Collect. Matched"::"Not Considered",
#if CLEAN19
          true);
#else
          true,
          // NAVCZ
          BankPmtApplRule."Variable Symbol Matched"::"Yes - Multiple",
          BankPmtApplRule."Specific Symbol Matched"::"Not Considered",
          BankPmtApplRule."Constant Symbol Matched"::"Not Considered",
          BankPmtApplRule."Bank Transaction Type"::Both);
        // NAVCZ
#endif

        InsertBankPaymentApplicationRule(
          BankPmtApplRule."Match Confidence"::High, RulePriority,
          BankPmtApplRule."Related Party Matched"::Fully,
#if CLEAN19
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes,
#else
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Not Considered", // NAVCZ
#endif
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"One Match",
          BankPmtApplRule."Direct Debit Collect. Matched"::"Not Considered",
#if CLEAN19
          true);
#else
          true,
          // NAVCZ
          BankPmtApplRule."Variable Symbol Matched"::Yes,
          BankPmtApplRule."Specific Symbol Matched"::"Not Considered",
          BankPmtApplRule."Constant Symbol Matched"::"Not Considered",
          BankPmtApplRule."Bank Transaction Type"::Both);
        // NAVCZ
#endif

        InsertBankPaymentApplicationRule(
          BankPmtApplRule."Match Confidence"::High, RulePriority,
          BankPmtApplRule."Related Party Matched"::Fully,
#if CLEAN19
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes,
#else
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Not Considered", // NAVCZ
#endif
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"Multiple Matches",
          BankPmtApplRule."Direct Debit Collect. Matched"::"Not Considered",
#if CLEAN19
          false);
#else
          true,
          // NAVCZ
          BankPmtApplRule."Variable Symbol Matched"::Yes,
          BankPmtApplRule."Specific Symbol Matched"::"Not Considered",
          BankPmtApplRule."Constant Symbol Matched"::"Not Considered",
          BankPmtApplRule."Bank Transaction Type"::Both);
        // NAVCZ
#endif

        InsertBankPaymentApplicationRule(
          BankPmtApplRule."Match Confidence"::High, RulePriority,
          BankPmtApplRule."Related Party Matched"::Partially,
#if CLEAN19
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Yes - Multiple",
#else
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Not Considered", // NAVCZ
#endif
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"One Match",
          BankPmtApplRule."Direct Debit Collect. Matched"::"Not Considered",
#if CLEAN19
          false);
#else
          false,
          // NAVCZ
          BankPmtApplRule."Variable Symbol Matched"::"Yes - Multiple",
          BankPmtApplRule."Specific Symbol Matched"::"Not Considered",
          BankPmtApplRule."Constant Symbol Matched"::"Not Considered",
          BankPmtApplRule."Bank Transaction Type"::Both);
        // NAVCZ
#endif

        InsertBankPaymentApplicationRule(
          BankPmtApplRule."Match Confidence"::High, RulePriority,
          BankPmtApplRule."Related Party Matched"::Partially,
#if CLEAN19
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Yes - Multiple",
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"Multiple Matches",
#else
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Not Considered", // NAVCZ
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"One Match", // NAVCZ
#endif
          BankPmtApplRule."Direct Debit Collect. Matched"::"Not Considered",
#if CLEAN19
          false);
#else
          false,
          // NAVCZ
          BankPmtApplRule."Variable Symbol Matched"::Yes,
          BankPmtApplRule."Specific Symbol Matched"::"Not Considered",
          BankPmtApplRule."Constant Symbol Matched"::"Not Considered",
          BankPmtApplRule."Bank Transaction Type"::Both);
        // NAVCZ
#endif

        InsertBankPaymentApplicationRule(
          BankPmtApplRule."Match Confidence"::High, RulePriority,
          BankPmtApplRule."Related Party Matched"::Partially,
#if CLEAN19
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes,
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"One Match",
#else
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Not Considered", // NAVCZ
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"Multiple Matches", // NAVCZ
#endif
          BankPmtApplRule."Direct Debit Collect. Matched"::"Not Considered",
#if CLEAN19
          false);
#else
          false,
          // NAVCZ
          BankPmtApplRule."Variable Symbol Matched"::Yes,
          BankPmtApplRule."Specific Symbol Matched"::"Not Considered",
          BankPmtApplRule."Constant Symbol Matched"::"Not Considered",
          BankPmtApplRule."Bank Transaction Type"::Both);
        // NAVCZ
#endif

        InsertBankPaymentApplicationRule(
          BankPmtApplRule."Match Confidence"::High, RulePriority,
          BankPmtApplRule."Related Party Matched"::Fully,
#if CLEAN19
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::No,
#else
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Not Considered", // NAVCZ
#endif
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"One Match",
          BankPmtApplRule."Direct Debit Collect. Matched"::"Not Considered",
#if CLEAN19
          false);
#else
          false,
          // NAVCZ
          BankPmtApplRule."Variable Symbol Matched"::No,
          BankPmtApplRule."Specific Symbol Matched"::"Not Considered",
          BankPmtApplRule."Constant Symbol Matched"::"Not Considered",
          BankPmtApplRule."Bank Transaction Type"::Both);
        // NAVCZ
#endif

        InsertBankPaymentApplicationRule(
          BankPmtApplRule."Match Confidence"::High, RulePriority,
          BankPmtApplRule."Related Party Matched"::No,
#if CLEAN19
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Yes - Multiple",
#else
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Not Considered", // NAVCZ
#endif
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"One Match",
          BankPmtApplRule."Direct Debit Collect. Matched"::"Not Considered",
#if CLEAN19
          false);
#else
          false,
          // NAVCZ
          BankPmtApplRule."Variable Symbol Matched"::"Yes - Multiple",
          BankPmtApplRule."Specific Symbol Matched"::"Not Considered",
          BankPmtApplRule."Constant Symbol Matched"::"Not Considered",
          BankPmtApplRule."Bank Transaction Type"::Both);
        // NAVCZ

        // NAVCZ
        InsertBankPaymentApplicationRule(
          BankPmtApplRule."Match Confidence"::High, RulePriority,
          BankPmtApplRule."Related Party Matched"::No,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Not Considered",
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"One Match",
          BankPmtApplRule."Direct Debit Collect. Matched"::"Not Considered",
          false,
          BankPmtApplRule."Variable Symbol Matched"::Yes,
          BankPmtApplRule."Specific Symbol Matched"::"Not Considered",
          BankPmtApplRule."Constant Symbol Matched"::"Not Considered",
          BankPmtApplRule."Bank Transaction Type"::Both);
        // NAVCZ
#endif

        InsertBankPaymentApplicationRule(
          BankPmtApplRule."Match Confidence"::High, RulePriority,
          BankPmtApplRule."Related Party Matched"::No,
#if CLEAN19
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Yes - Multiple",
#else
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Not Considered", // NAVCZ
#endif
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"Multiple Matches",
          BankPmtApplRule."Direct Debit Collect. Matched"::"Not Considered",
#if CLEAN19
          false);
#else
          false,
          // NAVCZ
          BankPmtApplRule."Variable Symbol Matched"::Yes,
          BankPmtApplRule."Specific Symbol Matched"::"Not Considered",
          BankPmtApplRule."Constant Symbol Matched"::"Not Considered",
          BankPmtApplRule."Bank Transaction Type"::Both);
        // NAVCZ
#endif

        // Insert Medium Confidence rules
        RulePriority := 1;
        InsertBankPaymentApplicationRule(
          BankPmtApplRule."Match Confidence"::Medium, RulePriority,
          BankPmtApplRule."Related Party Matched"::Fully,
#if CLEAN19
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Yes - Multiple",
#else
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Not Considered", // NAVCZ
#endif
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"Not Considered",
          BankPmtApplRule."Direct Debit Collect. Matched"::"Not Considered",
#if CLEAN19
          false);
#else
          false,
          // NAVCZ
          BankPmtApplRule."Variable Symbol Matched"::"Yes - Multiple",
          BankPmtApplRule."Specific Symbol Matched"::"Not Considered",
          BankPmtApplRule."Constant Symbol Matched"::"Not Considered",
          BankPmtApplRule."Bank Transaction Type"::Both);
        // NAVCZ
#endif

        InsertBankPaymentApplicationRule(
          BankPmtApplRule."Match Confidence"::Medium, RulePriority,
          BankPmtApplRule."Related Party Matched"::Fully,
#if CLEAN19
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes,
#else
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Not Considered", // NAVCZ
#endif
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"Not Considered",
          BankPmtApplRule."Direct Debit Collect. Matched"::"Not Considered",
#if CLEAN19
          false);
#else
          false,
          // NAVCZ
          BankPmtApplRule."Variable Symbol Matched"::Yes,
          BankPmtApplRule."Specific Symbol Matched"::"Not Considered",
          BankPmtApplRule."Constant Symbol Matched"::"Not Considered",
          BankPmtApplRule."Bank Transaction Type"::Both);
        // NAVCZ
#endif

        InsertBankPaymentApplicationRule(
          BankPmtApplRule."Match Confidence"::Medium, RulePriority,
          BankPmtApplRule."Related Party Matched"::Fully,
#if CLEAN19
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::No,
#else
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Not Considered",// NAVCZ
#endif
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"Multiple Matches",
          BankPmtApplRule."Direct Debit Collect. Matched"::"Not Considered",
#if CLEAN19
          false);
#else
          false,
          // NAVCZ
          BankPmtApplRule."Variable Symbol Matched"::No,
          BankPmtApplRule."Specific Symbol Matched"::"Not Considered",
          BankPmtApplRule."Constant Symbol Matched"::"Not Considered",
          BankPmtApplRule."Bank Transaction Type"::Both);
        // NAVCZ
#endif

        InsertBankPaymentApplicationRule(
          BankPmtApplRule."Match Confidence"::Medium, RulePriority,
          BankPmtApplRule."Related Party Matched"::Partially,
#if CLEAN19
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Yes - Multiple",
#else
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Not Considered", // NAVCZ
#endif
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"Not Considered",
          BankPmtApplRule."Direct Debit Collect. Matched"::"Not Considered",
#if CLEAN19
          false);
#else
          false,
          // NAVCZ
          BankPmtApplRule."Variable Symbol Matched"::"Yes - Multiple",
          BankPmtApplRule."Specific Symbol Matched"::"Not Considered",
          BankPmtApplRule."Constant Symbol Matched"::"Not Considered",
          BankPmtApplRule."Bank Transaction Type"::Both);
        // NAVCZ
#endif

        InsertBankPaymentApplicationRule(
          BankPmtApplRule."Match Confidence"::Medium, RulePriority,
          BankPmtApplRule."Related Party Matched"::Partially,
#if CLEAN19
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes,
#else
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Not Considered", // NAVCZ
#endif
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"Not Considered",
          BankPmtApplRule."Direct Debit Collect. Matched"::"Not Considered",
#if CLEAN19
          false);
#else
          false,
          // NAVCZ
          BankPmtApplRule."Variable Symbol Matched"::Yes,
          BankPmtApplRule."Specific Symbol Matched"::"Not Considered",
          BankPmtApplRule."Constant Symbol Matched"::"Not Considered",
          BankPmtApplRule."Bank Transaction Type"::Both);
        // NAVCZ
#endif

        InsertBankPaymentApplicationRule(
          BankPmtApplRule."Match Confidence"::Medium, RulePriority,
          BankPmtApplRule."Related Party Matched"::No,
#if CLEAN19
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes,
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"One Match",
          BankPmtApplRule."Direct Debit Collect. Matched"::"Not Considered",
          false);

        InsertBankPaymentApplicationRule(
          BankPmtApplRule."Match Confidence"::Medium, RulePriority,
          BankPmtApplRule."Related Party Matched"::No,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Yes - Multiple",
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"Not Considered",
          BankPmtApplRule."Direct Debit Collect. Matched"::"Not Considered",
          false);
#else
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Not Considered", // NAVCZ
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"Not Considered",
          BankPmtApplRule."Direct Debit Collect. Matched"::"Not Considered",
          false,
          // NAVCZ
          BankPmtApplRule."Variable Symbol Matched"::Yes,
          BankPmtApplRule."Specific Symbol Matched"::"Not Considered",
          BankPmtApplRule."Constant Symbol Matched"::"Not Considered",
          BankPmtApplRule."Bank Transaction Type"::Both);
        // NAVCZ
#endif

        InsertBankPaymentApplicationRule(
          BankPmtApplRule."Match Confidence"::Medium, RulePriority,
          BankPmtApplRule."Related Party Matched"::Partially,
#if CLEAN19
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::No,
#else
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Not Considered", // NAVCZ
#endif
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"One Match",
          BankPmtApplRule."Direct Debit Collect. Matched"::"Not Considered",
#if CLEAN19
          false);
#else
          false,
          // NAVCZ
          BankPmtApplRule."Variable Symbol Matched"::No,
          BankPmtApplRule."Specific Symbol Matched"::"Not Considered",
          BankPmtApplRule."Constant Symbol Matched"::"Not Considered",
          BankPmtApplRule."Bank Transaction Type"::Both);
        // NAVCZ
#endif

        InsertBankPaymentApplicationRule(
          BankPmtApplRule."Match Confidence"::Medium, RulePriority,
          BankPmtApplRule."Related Party Matched"::No,
#if CLEAN19
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::Yes,
#else
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Not Considered", // NAVCZ
#endif
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"Not Considered",
          BankPmtApplRule."Direct Debit Collect. Matched"::"Not Considered",
#if CLEAN19
          false);
#else
          false,
          // NAVCZ
          BankPmtApplRule."Variable Symbol Matched"::Yes,
          BankPmtApplRule."Specific Symbol Matched"::"Not Considered",
          BankPmtApplRule."Constant Symbol Matched"::"Not Considered",
          BankPmtApplRule."Bank Transaction Type"::Both);
        // NAVCZ
#endif

        // Insert Low Confidence rules
        RulePriority := 1;
        InsertBankPaymentApplicationRule(
          BankPmtApplRule."Match Confidence"::Low, RulePriority,
          BankPmtApplRule."Related Party Matched"::Fully,
#if CLEAN19
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::No,
#else
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Not Considered", // NAVCZ
#endif
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"No Matches",
          BankPmtApplRule."Direct Debit Collect. Matched"::"Not Considered",
#if CLEAN19
          false);
#else
          false,
          // NAVCZ
          BankPmtApplRule."Variable Symbol Matched"::No,
          BankPmtApplRule."Specific Symbol Matched"::"Not Considered",
          BankPmtApplRule."Constant Symbol Matched"::"Not Considered",
          BankPmtApplRule."Bank Transaction Type"::Both);
        // NAVCZ
#endif

        InsertBankPaymentApplicationRule(
          BankPmtApplRule."Match Confidence"::Low, RulePriority,
          BankPmtApplRule."Related Party Matched"::Partially,
#if CLEAN19
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::No,
#else
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Not Considered",// NAVCZ
#endif
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"Multiple Matches",
          BankPmtApplRule."Direct Debit Collect. Matched"::"Not Considered",
#if CLEAN19
          false);
#else
          false,
          // NAVCZ
          BankPmtApplRule."Variable Symbol Matched"::No,
          BankPmtApplRule."Specific Symbol Matched"::"Not Considered",
          BankPmtApplRule."Constant Symbol Matched"::"Not Considered",
          BankPmtApplRule."Bank Transaction Type"::Both);
        // NAVCZ
#endif

        InsertBankPaymentApplicationRule(
          BankPmtApplRule."Match Confidence"::Low, RulePriority,
          BankPmtApplRule."Related Party Matched"::Partially,
#if CLEAN19
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::No,
#else
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Not Considered", // NAVCZ
#endif
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"No Matches",
          BankPmtApplRule."Direct Debit Collect. Matched"::"Not Considered",
#if CLEAN19
          false);
#else
          false,
          // NAVCZ
          BankPmtApplRule."Variable Symbol Matched"::No,
          BankPmtApplRule."Specific Symbol Matched"::"Not Considered",
          BankPmtApplRule."Constant Symbol Matched"::"Not Considered",
          BankPmtApplRule."Bank Transaction Type"::Both);
        // NAVCZ
#endif

        InsertBankPaymentApplicationRule(
          BankPmtApplRule."Match Confidence"::Low, RulePriority,
          BankPmtApplRule."Related Party Matched"::No,
#if CLEAN19
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::No,
#else
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Not Considered", // NAVCZ
#endif
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"One Match",
          BankPmtApplRule."Direct Debit Collect. Matched"::"Not Considered",
#if CLEAN19
          false);
#else
          false,
          // NAVCZ
          BankPmtApplRule."Variable Symbol Matched"::No,
          BankPmtApplRule."Specific Symbol Matched"::"Not Considered",
          BankPmtApplRule."Constant Symbol Matched"::"Not Considered",
          BankPmtApplRule."Bank Transaction Type"::Both);
        // NAVCZ
#endif

        InsertBankPaymentApplicationRule(
          BankPmtApplRule."Match Confidence"::Low, RulePriority,
          BankPmtApplRule."Related Party Matched"::No,
#if CLEAN19
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::No,
#else
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Not Considered", // NAVCZ
#endif
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"Multiple Matches",
          BankPmtApplRule."Direct Debit Collect. Matched"::"Not Considered",
#if CLEAN19
          false);
#else
          false,
          // NAVCZ
          BankPmtApplRule."Variable Symbol Matched"::No,
          BankPmtApplRule."Specific Symbol Matched"::"Not Considered",
          BankPmtApplRule."Constant Symbol Matched"::"Not Considered",
          BankPmtApplRule."Bank Transaction Type"::Both);
        // NAVCZ
#endif
    end;

#if CLEAN19
    local procedure InsertBankPaymentApplicationRule(MatchConfidence: Option; var RulePriority: Integer; RelatedPartyIdentification: Option; DocumentMatch: Option; AmountMatch: Option; DirectDebitCollectionMatch: Option; ApplyAutomatically: Boolean)
#else
    local procedure InsertBankPaymentApplicationRule(MatchConfidence: Option; var RulePriority: Integer; RelatedPartyIdentification: Option; DocumentMatch: Option; AmountMatch: Option; DirectDebitCollectionMatch: Option; ApplyAutomatically: Boolean; VariableSymbolMatch: Option; SpecificSymbolMatch: Option; ConstantSymbolMatch: Option; BankTransactionType: Option)
#endif
    var
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
    begin
        BankPmtApplRule.Init();
#if CLEAN19
        BankPmtApplRule."Bank Pmt. Appl. Rule Code" := ''; // NAVCZ
#else
        BankPmtApplRule."Bank Pmt. Appl. Rule Code" := "Bank Pmt. Appl. Rule Code"; // NAVCZ
#endif
        BankPmtApplRule."Match Confidence" := MatchConfidence;
        BankPmtApplRule.Priority := RulePriority;
        BankPmtApplRule."Related Party Matched" := RelatedPartyIdentification;
        BankPmtApplRule."Doc. No./Ext. Doc. No. Matched" := DocumentMatch;
        BankPmtApplRule."Amount Incl. Tolerance Matched" := AmountMatch;
        BankPmtApplRule."Direct Debit Collect. Matched" := DirectDebitCollectionMatch;
        BankPmtApplRule."Apply Immediatelly" := ApplyAutomatically;

#if not CLEAN19
        // NAVCZ
        BankPmtApplRule."Variable Symbol Matched" := VariableSymbolMatch;
        BankPmtApplRule."Specific Symbol Matched" := SpecificSymbolMatch;
        BankPmtApplRule."Constant Symbol Matched" := ConstantSymbolMatch;
        BankPmtApplRule."Bank Transaction Type" := BankTransactionType;
        // NAVCZ

#endif
        if BankPmtApplRule."Match Confidence" in [BankPmtApplRule."Match Confidence"::None, BankPmtApplRule."Match Confidence"::Low, BankPmtApplRule."Match Confidence"::Medium] then
            BankPmtApplRule."Review Required" := true;

        BankPmtApplRule.Insert(true);
        RulePriority += 1;
    end;
#if not CLEAN19

    [Scope('OnPrem')]
    [Obsolete('Merge to W1.', '19.0')]
    procedure GetBankTransactionType(Amount: Decimal): Integer
    begin
        // NAVCZ
        case true of
            Amount < 0:
                exit("Bank Transaction Type"::"-");
            Amount > 0:
                exit("Bank Transaction Type"::"+");
        end;
    end;

    // NAV CZ
    [Obsolete('Merge to W1.', '19.0')]
    procedure FilterToBankAccountRules(BankAccReconcilationLine: Record "Bank Acc. Reconciliation Line"; var BankPmtApplRule: Record "Bank Pmt. Appl. Rule"): Boolean
    var
        BankAccount: Record "Bank Account";
    begin
        if BankAccReconcilationLine."Bank Account No." = '' then
            exit(false);

        if not BankAccount.Get(BankAccReconcilationLine."Bank Account No.") then
            exit(false);

        if BankAccount."Bank Pmt. Appl. Rule Code" = '' then
            exit(false);

        BankPmtApplRule.SetRange("Bank Pmt. Appl. Rule Code", BankAccount."Bank Pmt. Appl. Rule Code");
        exit(true);
    end;

    [Scope('OnPrem')]
    [Obsolete('Merge to W1.', '19.0')]
    procedure UpdateFromBankStmtMatchingBuffer(BankStmtMatchingBuffer: Record "Bank Statement Matching Buffer")
    begin
        // NAVCZ
        if not BankStmtMatchingBuffer."One to Many Match" then
            exit;

        case BankStmtMatchingBuffer."No. of Match to Doc. No." of
            0:
                "Doc. No./Ext. Doc. No. Matched" := "Doc. No./Ext. Doc. No. Matched"::No;
            1:
                "Doc. No./Ext. Doc. No. Matched" := "Doc. No./Ext. Doc. No. Matched"::Yes;
            else
                "Doc. No./Ext. Doc. No. Matched" := "Doc. No./Ext. Doc. No. Matched"::"Yes - Multiple";
        end;

        case BankStmtMatchingBuffer."No. of Match to V. Symbol" of
            0:
                "Variable Symbol Matched" := "Variable Symbol Matched"::No;
            1:
                "Variable Symbol Matched" := "Variable Symbol Matched"::Yes;
            else
                "Variable Symbol Matched" := "Variable Symbol Matched"::"Yes - Multiple";
        end;

        case BankStmtMatchingBuffer."No. of Match to S. Symbol" of
            0:
                "Specific Symbol Matched" := "Specific Symbol Matched"::No;
            1:
                "Specific Symbol Matched" := "Specific Symbol Matched"::Yes;
            else
                "Specific Symbol Matched" := "Specific Symbol Matched"::"Yes - Multiple";
        end;

        case BankStmtMatchingBuffer."No. of Match to C. Symbol" of
            0:
                "Constant Symbol Matched" := "Constant Symbol Matched"::No;
            1:
                "Constant Symbol Matched" := "Constant Symbol Matched"::Yes;
            else
                "Constant Symbol Matched" := "Constant Symbol Matched"::"Yes - Multiple";
        end;
    end;
#endif
}

