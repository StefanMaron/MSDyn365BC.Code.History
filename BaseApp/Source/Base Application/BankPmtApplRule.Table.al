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
        field(11700; "Bank Pmt. Appl. Rule Code"; Code[10])
        {
            Caption = 'Bank Pmt. Appl. Rule Code';
            TableRelation = "Bank Pmt. Appl. Rule Code";
        }
        field(11705; "Variable Symbol Matched"; Option)
        {
            Caption = 'Variable Symbol Matched';
            OptionCaption = 'Not Considered,Yes,No,Yes - Multiple';
            OptionMembers = "Not Considered",Yes,No,"Yes - Multiple";
        }
        field(11706; "Specific Symbol Matched"; Option)
        {
            Caption = 'Specific Symbol Matched';
            OptionCaption = 'Not Considered,Yes,No,Yes - Multiple';
            OptionMembers = "Not Considered",Yes,No,"Yes - Multiple";
        }
        field(11707; "Constant Symbol Matched"; Option)
        {
            Caption = 'Constant Symbol Matched';
            OptionCaption = 'Not Considered,Yes,No,Yes - Multiple';
            OptionMembers = "Not Considered",Yes,No,"Yes - Multiple";
        }
        field(11710; "Bank Transaction Type"; Option)
        {
            Caption = 'Bank Transaction Type';
            OptionCaption = 'Both,+,-';
            OptionMembers = Both,"+","-";
        }
    }

    keys
    {
        key(Key1; "Bank Pmt. Appl. Rule Code", "Match Confidence", Priority)
        {
            Clustered = true;
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

    procedure LoadRules(BankPmtApplRuleCode: Code[10])
    var
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
    begin
        if not IsTemporary then
            Error(LoadRulesOnlyOnTempRecordsErr);

        DeleteAll();
        BankPmtApplRule.SetRange("Bank Pmt. Appl. Rule Code", BankPmtApplRuleCode); // NAVCZ
        if BankPmtApplRule.FindSet then
            repeat
                TransferFields(BankPmtApplRule);
                Insert;
            until BankPmtApplRule.Next = 0;
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

        if FindFirst then
            exit(Score);

        exit(0);
    end;

    procedure GetTextMapperScore(): Integer
    var
        MediumConfidenceHighestScore: Integer;
    begin
        // Text mapper should override only Medium confidence and lower
        MediumConfidenceHighestScore := CalculateScore("Match Confidence"::Medium, Priority); // NAVCZ
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

    procedure GetMatchConfidence(MatchQuality: Integer; IsTextMapper: Boolean): Integer
    var
        BankAccReconciliationLine: Record "Bank Acc. Reconciliation Line";
        OptionNo: Integer;
    begin
        if IsTextMapper then // NAVCZ
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
        BankPmtApplRule.SetRange("Bank Pmt. Appl. Rule Code", "Bank Pmt. Appl. Rule Code"); // NAVCZ
        if not BankPmtApplRule.IsEmpty then
            exit;

        // Insert High Confidence rules
        RulePriority := 1;
        InsertBankPaymentApplicationRule(
          BankPmtApplRule."Match Confidence"::High, RulePriority,
          BankPmtApplRule."Related Party Matched"::"Not Considered",
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Not Considered",
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"Not Considered",
          BankPmtApplRule."Direct Debit Collect. Matched"::Yes,
          // NAVCZ
          BankPmtApplRule."Variable Symbol Matched"::"Not Considered",
          BankPmtApplRule."Specific Symbol Matched"::"Not Considered",
          BankPmtApplRule."Constant Symbol Matched"::"Not Considered",
          BankPmtApplRule."Bank Transaction Type"::Both);
        // NAVCZ;

        InsertBankPaymentApplicationRule(
          BankPmtApplRule."Match Confidence"::High, RulePriority,
          BankPmtApplRule."Related Party Matched"::Fully,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Not Considered", // NAVCZ
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"One Match",
          BankPmtApplRule."Direct Debit Collect. Matched"::"Not Considered",
          // NAVCZ
          BankPmtApplRule."Variable Symbol Matched"::"Yes - Multiple",
          BankPmtApplRule."Specific Symbol Matched"::"Not Considered",
          BankPmtApplRule."Constant Symbol Matched"::"Not Considered",
          BankPmtApplRule."Bank Transaction Type"::Both);
        // NAVCZ

        InsertBankPaymentApplicationRule(
          BankPmtApplRule."Match Confidence"::High, RulePriority,
          BankPmtApplRule."Related Party Matched"::Fully,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Not Considered", // NAVCZ
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"Multiple Matches",
          BankPmtApplRule."Direct Debit Collect. Matched"::"Not Considered",
          // NAVCZ
          BankPmtApplRule."Variable Symbol Matched"::"Yes - Multiple",
          BankPmtApplRule."Specific Symbol Matched"::"Not Considered",
          BankPmtApplRule."Constant Symbol Matched"::"Not Considered",
          BankPmtApplRule."Bank Transaction Type"::Both);
        // NAVCZ

        InsertBankPaymentApplicationRule(
          BankPmtApplRule."Match Confidence"::High, RulePriority,
          BankPmtApplRule."Related Party Matched"::Fully,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Not Considered", // NAVCZ
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"One Match",
          BankPmtApplRule."Direct Debit Collect. Matched"::"Not Considered",
          // NAVCZ
          BankPmtApplRule."Variable Symbol Matched"::Yes,
          BankPmtApplRule."Specific Symbol Matched"::"Not Considered",
          BankPmtApplRule."Constant Symbol Matched"::"Not Considered",
          BankPmtApplRule."Bank Transaction Type"::Both);
        // NAVCZ

        InsertBankPaymentApplicationRule(
          BankPmtApplRule."Match Confidence"::High, RulePriority,
          BankPmtApplRule."Related Party Matched"::Fully,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Not Considered", // NAVCZ
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"Multiple Matches",
          BankPmtApplRule."Direct Debit Collect. Matched"::"Not Considered",
          // NAVCZ
          BankPmtApplRule."Variable Symbol Matched"::Yes,
          BankPmtApplRule."Specific Symbol Matched"::"Not Considered",
          BankPmtApplRule."Constant Symbol Matched"::"Not Considered",
          BankPmtApplRule."Bank Transaction Type"::Both);
        // NAVCZ

        InsertBankPaymentApplicationRule(
          BankPmtApplRule."Match Confidence"::High, RulePriority,
          BankPmtApplRule."Related Party Matched"::Partially,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Not Considered", // NAVCZ
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"One Match",
          BankPmtApplRule."Direct Debit Collect. Matched"::"Not Considered",
          // NAVCZ
          BankPmtApplRule."Variable Symbol Matched"::"Yes - Multiple",
          BankPmtApplRule."Specific Symbol Matched"::"Not Considered",
          BankPmtApplRule."Constant Symbol Matched"::"Not Considered",
          BankPmtApplRule."Bank Transaction Type"::Both);
        // NAVCZ

        InsertBankPaymentApplicationRule(
          BankPmtApplRule."Match Confidence"::High, RulePriority,
          BankPmtApplRule."Related Party Matched"::Partially,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Not Considered", // NAVCZ
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"One Match", // NAVCZ
          BankPmtApplRule."Direct Debit Collect. Matched"::"Not Considered",
          // NAVCZ
          BankPmtApplRule."Variable Symbol Matched"::Yes,
          BankPmtApplRule."Specific Symbol Matched"::"Not Considered",
          BankPmtApplRule."Constant Symbol Matched"::"Not Considered",
          BankPmtApplRule."Bank Transaction Type"::Both);
        // NAVCZ

        InsertBankPaymentApplicationRule(
          BankPmtApplRule."Match Confidence"::High, RulePriority,
          BankPmtApplRule."Related Party Matched"::Partially,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Not Considered", // NAVCZ
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"Multiple Matches", // NAVCZ
          BankPmtApplRule."Direct Debit Collect. Matched"::"Not Considered",
          // NAVCZ
          BankPmtApplRule."Variable Symbol Matched"::Yes,
          BankPmtApplRule."Specific Symbol Matched"::"Not Considered",
          BankPmtApplRule."Constant Symbol Matched"::"Not Considered",
          BankPmtApplRule."Bank Transaction Type"::Both);
        // NAVCZ

        InsertBankPaymentApplicationRule(
          BankPmtApplRule."Match Confidence"::High, RulePriority,
          BankPmtApplRule."Related Party Matched"::Fully,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Not Considered", // NAVCZ
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"One Match",
          BankPmtApplRule."Direct Debit Collect. Matched"::"Not Considered",
          // NAVCZ
          BankPmtApplRule."Variable Symbol Matched"::No,
          BankPmtApplRule."Specific Symbol Matched"::"Not Considered",
          BankPmtApplRule."Constant Symbol Matched"::"Not Considered",
          BankPmtApplRule."Bank Transaction Type"::Both);
        // NAVCZ

        InsertBankPaymentApplicationRule(
          BankPmtApplRule."Match Confidence"::High, RulePriority,
          BankPmtApplRule."Related Party Matched"::No,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Not Considered", // NAVCZ
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"One Match",
          BankPmtApplRule."Direct Debit Collect. Matched"::"Not Considered",
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
          BankPmtApplRule."Variable Symbol Matched"::Yes,
          BankPmtApplRule."Specific Symbol Matched"::"Not Considered",
          BankPmtApplRule."Constant Symbol Matched"::"Not Considered",
          BankPmtApplRule."Bank Transaction Type"::Both);
        // NAVCZ

        InsertBankPaymentApplicationRule(
          BankPmtApplRule."Match Confidence"::High, RulePriority,
          BankPmtApplRule."Related Party Matched"::No,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Not Considered", // NAVCZ
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"Multiple Matches",
          BankPmtApplRule."Direct Debit Collect. Matched"::"Not Considered",
          // NAVCZ
          BankPmtApplRule."Variable Symbol Matched"::Yes,
          BankPmtApplRule."Specific Symbol Matched"::"Not Considered",
          BankPmtApplRule."Constant Symbol Matched"::"Not Considered",
          BankPmtApplRule."Bank Transaction Type"::Both);
        // NAVCZ

        // Insert Medium Confidence rules
        RulePriority := 1;
        InsertBankPaymentApplicationRule(
          BankPmtApplRule."Match Confidence"::Medium, RulePriority,
          BankPmtApplRule."Related Party Matched"::Fully,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Not Considered", // NAVCZ
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"Not Considered",
          BankPmtApplRule."Direct Debit Collect. Matched"::"Not Considered",
          // NAVCZ
          BankPmtApplRule."Variable Symbol Matched"::"Yes - Multiple",
          BankPmtApplRule."Specific Symbol Matched"::"Not Considered",
          BankPmtApplRule."Constant Symbol Matched"::"Not Considered",
          BankPmtApplRule."Bank Transaction Type"::Both);
        // NAVCZ

        InsertBankPaymentApplicationRule(
          BankPmtApplRule."Match Confidence"::Medium, RulePriority,
          BankPmtApplRule."Related Party Matched"::Fully,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Not Considered", // NAVCZ
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"Not Considered",
          BankPmtApplRule."Direct Debit Collect. Matched"::"Not Considered",
          // NAVCZ
          BankPmtApplRule."Variable Symbol Matched"::Yes,
          BankPmtApplRule."Specific Symbol Matched"::"Not Considered",
          BankPmtApplRule."Constant Symbol Matched"::"Not Considered",
          BankPmtApplRule."Bank Transaction Type"::Both);
        // NAVCZ

        InsertBankPaymentApplicationRule(
          BankPmtApplRule."Match Confidence"::Medium, RulePriority,
          BankPmtApplRule."Related Party Matched"::Fully,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Not Considered",// NAVCZ
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"Multiple Matches",
          BankPmtApplRule."Direct Debit Collect. Matched"::"Not Considered",
          // NAVCZ
          BankPmtApplRule."Variable Symbol Matched"::No,
          BankPmtApplRule."Specific Symbol Matched"::"Not Considered",
          BankPmtApplRule."Constant Symbol Matched"::"Not Considered",
          BankPmtApplRule."Bank Transaction Type"::Both);
        // NAVCZ

        InsertBankPaymentApplicationRule(
          BankPmtApplRule."Match Confidence"::Medium, RulePriority,
          BankPmtApplRule."Related Party Matched"::Partially,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Not Considered", // NAVCZ
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"Not Considered",
          BankPmtApplRule."Direct Debit Collect. Matched"::"Not Considered",
          // NAVCZ
          BankPmtApplRule."Variable Symbol Matched"::"Yes - Multiple",
          BankPmtApplRule."Specific Symbol Matched"::"Not Considered",
          BankPmtApplRule."Constant Symbol Matched"::"Not Considered",
          BankPmtApplRule."Bank Transaction Type"::Both);
        // NAVCZ

        InsertBankPaymentApplicationRule(
          BankPmtApplRule."Match Confidence"::Medium, RulePriority,
          BankPmtApplRule."Related Party Matched"::Partially,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Not Considered", // NAVCZ
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"Not Considered",
          BankPmtApplRule."Direct Debit Collect. Matched"::"Not Considered",
          // NAVCZ
          BankPmtApplRule."Variable Symbol Matched"::Yes,
          BankPmtApplRule."Specific Symbol Matched"::"Not Considered",
          BankPmtApplRule."Constant Symbol Matched"::"Not Considered",
          BankPmtApplRule."Bank Transaction Type"::Both);
        // NAVCZ

        InsertBankPaymentApplicationRule(
          BankPmtApplRule."Match Confidence"::Medium, RulePriority,
          BankPmtApplRule."Related Party Matched"::No,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Not Considered", // NAVCZ
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"Not Considered",
          BankPmtApplRule."Direct Debit Collect. Matched"::"Not Considered",
          // NAVCZ
          BankPmtApplRule."Variable Symbol Matched"::Yes,
          BankPmtApplRule."Specific Symbol Matched"::"Not Considered",
          BankPmtApplRule."Constant Symbol Matched"::"Not Considered",
          BankPmtApplRule."Bank Transaction Type"::Both);
        // NAVCZ

        InsertBankPaymentApplicationRule(
          BankPmtApplRule."Match Confidence"::Medium, RulePriority,
          BankPmtApplRule."Related Party Matched"::Partially,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Not Considered", // NAVCZ
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"One Match",
          BankPmtApplRule."Direct Debit Collect. Matched"::"Not Considered",
          // NAVCZ
          BankPmtApplRule."Variable Symbol Matched"::No,
          BankPmtApplRule."Specific Symbol Matched"::"Not Considered",
          BankPmtApplRule."Constant Symbol Matched"::"Not Considered",
          BankPmtApplRule."Bank Transaction Type"::Both);
        // NAVCZ

        InsertBankPaymentApplicationRule(
          BankPmtApplRule."Match Confidence"::Medium, RulePriority,
          BankPmtApplRule."Related Party Matched"::No,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Not Considered", // NAVCZ
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"Not Considered",
          BankPmtApplRule."Direct Debit Collect. Matched"::"Not Considered",
          // NAVCZ
          BankPmtApplRule."Variable Symbol Matched"::Yes,
          BankPmtApplRule."Specific Symbol Matched"::"Not Considered",
          BankPmtApplRule."Constant Symbol Matched"::"Not Considered",
          BankPmtApplRule."Bank Transaction Type"::Both);
        // NAVCZ

        // Insert Low Confidence rules
        RulePriority := 1;
        InsertBankPaymentApplicationRule(
          BankPmtApplRule."Match Confidence"::Low, RulePriority,
          BankPmtApplRule."Related Party Matched"::Fully,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Not Considered", // NAVCZ
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"No Matches",
          BankPmtApplRule."Direct Debit Collect. Matched"::"Not Considered",
          // NAVCZ
          BankPmtApplRule."Variable Symbol Matched"::No,
          BankPmtApplRule."Specific Symbol Matched"::"Not Considered",
          BankPmtApplRule."Constant Symbol Matched"::"Not Considered",
          BankPmtApplRule."Bank Transaction Type"::Both);
        // NAVCZ

        InsertBankPaymentApplicationRule(
          BankPmtApplRule."Match Confidence"::Low, RulePriority,
          BankPmtApplRule."Related Party Matched"::Partially,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Not Considered",// NAVCZ
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"Multiple Matches",
          BankPmtApplRule."Direct Debit Collect. Matched"::"Not Considered",
          // NAVCZ
          BankPmtApplRule."Variable Symbol Matched"::No,
          BankPmtApplRule."Specific Symbol Matched"::"Not Considered",
          BankPmtApplRule."Constant Symbol Matched"::"Not Considered",
          BankPmtApplRule."Bank Transaction Type"::Both);
        // NAVCZ

        InsertBankPaymentApplicationRule(
          BankPmtApplRule."Match Confidence"::Low, RulePriority,
          BankPmtApplRule."Related Party Matched"::Partially,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Not Considered", // NAVCZ
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"No Matches",
          BankPmtApplRule."Direct Debit Collect. Matched"::"Not Considered",
          // NAVCZ
          BankPmtApplRule."Variable Symbol Matched"::No,
          BankPmtApplRule."Specific Symbol Matched"::"Not Considered",
          BankPmtApplRule."Constant Symbol Matched"::"Not Considered",
          BankPmtApplRule."Bank Transaction Type"::Both);
        // NAVCZ

        InsertBankPaymentApplicationRule(
          BankPmtApplRule."Match Confidence"::Low, RulePriority,
          BankPmtApplRule."Related Party Matched"::No,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Not Considered", // NAVCZ
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"One Match",
          BankPmtApplRule."Direct Debit Collect. Matched"::"Not Considered",
          // NAVCZ
          BankPmtApplRule."Variable Symbol Matched"::No,
          BankPmtApplRule."Specific Symbol Matched"::"Not Considered",
          BankPmtApplRule."Constant Symbol Matched"::"Not Considered",
          BankPmtApplRule."Bank Transaction Type"::Both);
        // NAVCZ

        InsertBankPaymentApplicationRule(
          BankPmtApplRule."Match Confidence"::Low, RulePriority,
          BankPmtApplRule."Related Party Matched"::No,
          BankPmtApplRule."Doc. No./Ext. Doc. No. Matched"::"Not Considered", // NAVCZ
          BankPmtApplRule."Amount Incl. Tolerance Matched"::"Multiple Matches",
          BankPmtApplRule."Direct Debit Collect. Matched"::"Not Considered",
          // NAVCZ
          BankPmtApplRule."Variable Symbol Matched"::No,
          BankPmtApplRule."Specific Symbol Matched"::"Not Considered",
          BankPmtApplRule."Constant Symbol Matched"::"Not Considered",
          BankPmtApplRule."Bank Transaction Type"::Both);
        // NAVCZ
    end;

    local procedure InsertBankPaymentApplicationRule(MatchConfidence: Option; var RulePriority: Integer; RelatedPartyIdentification: Option; DocumentMatch: Option; AmountMatch: Option; DirectDebitCollectionMatch: Option; VariableSymbolMatch: Option; SpecificSymbolMatch: Option; ConstantSymbolMatch: Option; BankTransactionType: Option)
    var
        BankPmtApplRule: Record "Bank Pmt. Appl. Rule";
    begin
        BankPmtApplRule.Init();
        BankPmtApplRule."Bank Pmt. Appl. Rule Code" := "Bank Pmt. Appl. Rule Code"; // NAVCZ
        BankPmtApplRule."Match Confidence" := MatchConfidence;
        BankPmtApplRule.Priority := RulePriority;
        BankPmtApplRule."Related Party Matched" := RelatedPartyIdentification;
        BankPmtApplRule."Doc. No./Ext. Doc. No. Matched" := DocumentMatch;
        BankPmtApplRule."Amount Incl. Tolerance Matched" := AmountMatch;
        BankPmtApplRule."Direct Debit Collect. Matched" := DirectDebitCollectionMatch;
        // NAVCZ
        BankPmtApplRule."Variable Symbol Matched" := VariableSymbolMatch;
        BankPmtApplRule."Specific Symbol Matched" := SpecificSymbolMatch;
        BankPmtApplRule."Constant Symbol Matched" := ConstantSymbolMatch;
        BankPmtApplRule."Bank Transaction Type" := BankTransactionType;
        // NAVCZ
        BankPmtApplRule.Insert(true);
        RulePriority += 1;
    end;

    [Scope('OnPrem')]
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

    [Scope('OnPrem')]
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
}

