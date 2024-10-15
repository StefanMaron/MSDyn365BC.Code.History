codeunit 11795 "User Setup Adv. Management"
{
    Permissions = TableData "User Setup" = m;
    TableNo = "User Setup";

    trigger OnRun()
    begin
        Modify;
    end;

    var
        Item: Record Item;
        UserSetup: Record "User Setup";
        JournalPermErr: Label 'Access to journal %1 is not allowed in extended user check.', Comment = '%1 = journal template code';
        ReqWkshPermErr: Label 'Access to worksheet %1 is not allowed in extended user check.', Comment = '%1 = journal template code';
        VATStmtPermErr: Label 'Access to statement %1 is not allowed in extended user check.', Comment = '%1 = journal template code';
        PaymOrdDeniedErr: Label 'Access to payment orders of bank account %1 is not allowed in extended user check.', Comment = '%1 = bank account number';
        BankStmtDeniedErr: Label 'Access to bank statements of bank account %1 is not allowed in extended user check.', Comment = '%1 = bank account number';

    [TryFunction]
    [Scope('OnPrem')]
    procedure CheckJournalTemplate(Type: Option; JournalTemplateCode: Code[10])
    var
        UserSetupLine: Record "User Setup Line";
    begin
        if not IsCheckAllowed then
            exit;

        GetUserSetup;
        if not UserSetup."Check Journal Templates" then
            exit;

        if not CheckUserSetupLine(UserSetup."User ID", Type, JournalTemplateCode) then
            case Type of
                UserSetupLine.Type::"Req. Worksheet":
                    Error(ReqWkshPermErr, JournalTemplateCode);
                UserSetupLine.Type::"VAT Statement":
                    Error(VATStmtPermErr, JournalTemplateCode);
                else
                    Error(JournalPermErr, JournalTemplateCode);
            end;
    end;

    [TryFunction]
    [Scope('OnPrem')]
    procedure CheckGeneralJournalLine(GeneralJournalLine: Record "Gen. Journal Line")
    begin
        with GeneralJournalLine do begin
            if "Document Date" <> 0D then begin
                if not CheckWorkDocDate("Document Date") then
                    TestField("Document Date", WorkDate);
                if not CheckSysDocDate("Document Date") then
                    TestField("Document Date", Today);
            end;
            if not CheckWorkPostingDate("Posting Date") then
                TestField("Posting Date", WorkDate);
            if not CheckSysPostingDate("Posting Date") then
                TestField("Posting Date", Today);

            // Bank Account checks
            if ("Account Type" = "Account Type"::"Bank Account") and ("Account No." <> '') then
                if not CheckBankAccount("Account No.") then
                    FieldError("Account No.");
            if ("Bal. Account Type" = "Bal. Account Type"::"Bank Account") and ("Bal. Account No." <> '') then
                if not CheckBankAccount("Bal. Account No.") then
                    FieldError("Bal. Account No.");
        end;
    end;

    [TryFunction]
    [Scope('OnPrem')]
    procedure CheckItemJournalLine(ItemJournalLine: Record "Item Journal Line")
    begin
        with ItemJournalLine do begin
            if not CheckWorkDocDate("Document Date") then
                TestField("Document Date", WorkDate);
            if not CheckSysDocDate("Document Date") then
                TestField("Document Date", Today);
            if not CheckWorkPostingDate("Posting Date") then
                TestField("Posting Date", WorkDate);
            if not CheckSysPostingDate("Posting Date") then
                TestField("Posting Date", Today);

            // Location checks
            if "Value Entry Type" <> "Value Entry Type"::Revaluation then begin
                if not Item.Get("Item No.") then
                    Item.Init();
                case "Entry Type" of
                    "Entry Type"::Purchase, "Entry Type"::"Positive Adjmt.", "Entry Type"::Output:
                        if Quantity > 0 then begin
                            if not CheckLocQuantityIncrease("Location Code") then
                                FieldError("Location Code")
                        end else begin
                            if Quantity < 0 then
                                if not CheckLocQuantityDecrease("Location Code") then
                                    FieldError("Location Code");
                        end;
                    "Entry Type"::Sale, "Entry Type"::"Negative Adjmt.", "Entry Type"::Consumption:
                        if Quantity > 0 then begin
                            if not CheckLocQuantityDecrease("Location Code") then
                                FieldError("Location Code")
                        end else begin
                            if Quantity < 0 then
                                if not CheckLocQuantityIncrease("Location Code") then
                                    FieldError("Location Code");
                        end;
                    "Entry Type"::Transfer:
                        begin
                            if not CheckLocQuantityDecrease("Location Code") then
                                FieldError("Location Code");
                            if not CheckLocQuantityIncrease("New Location Code") then
                                FieldError("New Location Code");
                        end;
                end;
            end;
            if not CheckWhseNetChangeTemplate(ItemJournalLine) then
                FieldError("Whse. Net Change Template");
        end;
    end;

    [TryFunction]
    [Scope('OnPrem')]
    procedure CheckJobJournalLine(JobJournalLine: Record "Job Journal Line")
    begin
        with JobJournalLine do begin
            if not CheckWorkDocDate("Document Date") then
                TestField("Document Date", WorkDate);
            if not CheckSysDocDate("Document Date") then
                TestField("Document Date", Today);
            if not CheckWorkPostingDate("Posting Date") then
                TestField("Posting Date", WorkDate);
            if not CheckSysPostingDate("Posting Date") then
                TestField("Posting Date", Today);
        end;
    end;

    [TryFunction]
    [Scope('OnPrem')]
    procedure CheckResJournalLine(ResJournalLine: Record "Res. Journal Line")
    begin
        with ResJournalLine do begin
            if not CheckWorkDocDate("Document Date") then
                TestField("Document Date", WorkDate);
            if not CheckSysDocDate("Document Date") then
                TestField("Document Date", Today);
            if not CheckWorkPostingDate("Posting Date") then
                TestField("Posting Date", WorkDate);
            if not CheckSysPostingDate("Posting Date") then
                TestField("Posting Date", Today);
        end;
    end;

    [TryFunction]
    [Scope('OnPrem')]
    procedure CheckInsuranceJournalLine(InsuranceJournalLine: Record "Insurance Journal Line")
    begin
        with InsuranceJournalLine do begin
            if not CheckWorkDocDate("Document Date") then
                TestField("Document Date", WorkDate);
            if not CheckSysDocDate("Document Date") then
                TestField("Document Date", Today);
            if not CheckWorkPostingDate("Posting Date") then
                TestField("Posting Date", WorkDate);
            if not CheckSysPostingDate("Posting Date") then
                TestField("Posting Date", Today);
        end;
    end;

    [Scope('OnPrem')]
    procedure CheckWorkDocDate(Date: Date): Boolean
    begin
        GetUserSetup;
        if not UserSetup."Check Document Date(work date)" then
            exit(true);
        exit(Date = WorkDate);
    end;

    [Scope('OnPrem')]
    procedure CheckSysDocDate(Date: Date): Boolean
    begin
        GetUserSetup;
        if not UserSetup."Check Document Date(sys. date)" then
            exit(true);
        exit(Date = Today);
    end;

    [Scope('OnPrem')]
    procedure CheckWorkPostingDate(Date: Date): Boolean
    begin
        GetUserSetup;
        if not UserSetup."Check Posting Date (work date)" then
            exit(true);
        exit(Date = WorkDate);
    end;

    [Scope('OnPrem')]
    procedure CheckSysPostingDate(Date: Date): Boolean
    begin
        GetUserSetup;
        if not UserSetup."Check Posting Date (sys. date)" then
            exit(true);
        exit(Date = Today);
    end;

    [Scope('OnPrem')]
    procedure CheckLocQuantityIncrease(LocationCode: Code[10]): Boolean
    var
        UserSetupLine: Record "User Setup Line";
    begin
        GetUserSetup;
        if not UserSetup."Check Location Code" then
            exit(true);

        if Item.IsNonInventoriableType() then
            exit(true);

        exit(CheckUserSetupLine(UserSetup."User ID", UserSetupLine.Type::"Location (quantity increase)", LocationCode));
    end;

    [Scope('OnPrem')]
    procedure CheckLocQuantityDecrease(LocationCode: Code[10]): Boolean
    var
        UserSetupLine: Record "User Setup Line";
    begin
        GetUserSetup;
        if not UserSetup."Check Location Code" then
            exit(true);

        if Item.IsNonInventoriableType() then
            exit(true);

        exit(CheckUserSetupLine(UserSetup."User ID", UserSetupLine.Type::"Location (quantity decrease)", LocationCode));
    end;

    [Scope('OnPrem')]
    procedure CheckBankAccount(BankAcc: Code[20]): Boolean
    var
        UserSetupLine: Record "User Setup Line";
    begin
        GetUserSetup;
        if not UserSetup."Check Bank Accounts" then
            exit(true);

        exit(CheckUserSetupLine(UserSetup."User ID", UserSetupLine.Type::"Bank Account", BankAcc));
    end;

    [Scope('OnPrem')]
    procedure CheckFiscalYear(GLEntry: Record "G/L Entry"): Boolean
    begin
        GetUserSetup;
        if not UserSetup."Allow Posting to Closed Period" then
            GLEntry.TestField("Prior-Year Entry", false);
        exit(true);
    end;

    [Scope('OnPrem')]
    procedure CheckItemUnapply()
    begin
        GetUserSetup;
        UserSetup.TestField("Allow Item Unapply", true);
    end;

    [Scope('OnPrem')]
    procedure SelectDimensionsToCheck(UserSetup2: Record "User Setup")
    var
        Dim: Record Dimension;
        TempDimSelectionBuf: Record "Dimension Selection Buffer" temporary;
        SelectedDim: Record "Selected Dimension";
        DimSelectionChange: Page "Dimension Selection-Change";
    begin
        Clear(DimSelectionChange);
        if Dim.Find('-') then
            repeat
                DimSelectionChange.InsertDimSelBuf(
                  SelectedDim.Get(UserSetup2."User ID", 1, DATABASE::"User Setup", '', Dim.Code),
                  Dim.Code, Dim.GetMLName(GlobalLanguage),
                  SelectedDim."New Dimension Value Code",
                  SelectedDim."Dimension Value Filter");
            until Dim.Next = 0;

        DimSelectionChange.LookupMode := true;
        if DimSelectionChange.RunModal = ACTION::LookupOK then begin
            DimSelectionChange.GetDimSelBuf(TempDimSelectionBuf);
            // Set Dimension Selection
            SelectedDim.SetRange("User ID", UserSetup2."User ID");
            SelectedDim.SetRange("Object Type", 1);
            SelectedDim.SetRange("Object ID", DATABASE::"User Setup");
            SelectedDim.SetRange("Analysis View Code", '');
            SelectedDim.DeleteAll;
            TempDimSelectionBuf.SetCurrentKey(Level, Code);
            TempDimSelectionBuf.SetRange(Selected, true);
            if TempDimSelectionBuf.Find('-') then
                repeat
                    SelectedDim."User ID" := UserSetup2."User ID";
                    SelectedDim."Object Type" := 1;
                    SelectedDim."Object ID" := DATABASE::"User Setup";
                    SelectedDim."Analysis View Code" := '';
                    SelectedDim."Dimension Code" := TempDimSelectionBuf.Code;
                    SelectedDim."New Dimension Value Code" := TempDimSelectionBuf."New Dimension Value Code";
                    SelectedDim."Dimension Value Filter" := TempDimSelectionBuf."Dimension Value Filter";
                    SelectedDim.Level := TempDimSelectionBuf.Level;
                    SelectedDim.Insert;
                until TempDimSelectionBuf.Next = 0;
        end;
    end;

    [TryFunction]
    [Scope('OnPrem')]
    procedure GetUserSetup()
    var
        TempUserID: Code[50];
    begin
        TempUserID := GetUserID;
        if UserSetup."User ID" <> TempUserID then
            UserSetup.Get(TempUserID);
    end;

    [Scope('OnPrem')]
    procedure GetUserID() TempUserID: Code[50]
    begin
        TempUserID := UserId;
    end;

    [Scope('OnPrem')]
    procedure CheckBankAccountNo(Type: Option; BankAccNo: Code[20])
    var
        UserSetupLine: Record "User Setup Line";
    begin
        GetUserSetup;
        if not UserSetup."Check Payment Orders" and not UserSetup."Check Bank Statements" then
            exit;

        if not CheckUserSetupLine(UserSetup."User ID", Type, BankAccNo) then
            case true of
                (Type = UserSetupLine.Type::"Paym. Order") and UserSetup."Check Payment Orders":
                    Error(PaymOrdDeniedErr, BankAccNo);
                (Type = UserSetupLine.Type::"Bank Stmt") and UserSetup."Check Bank Statements":
                    Error(BankStmtDeniedErr, BankAccNo);
            end;
    end;

    [Scope('OnPrem')]
    procedure CheckWhseNetChangeTemplate(var ItemJnlLine: Record "Item Journal Line"): Boolean
    var
        UserSetupLine: Record "User Setup Line";
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        if (ItemJnlLine."Source Type" = ItemJnlLine."Source Type"::Customer) or
           (ItemJnlLine."Source Type" = ItemJnlLine."Source Type"::Vendor) or
           (ItemJnlLine."Source Type" = ItemJnlLine."Source Type"::Item) or
           (ItemJnlLine."Order No." <> '') or
           ItemJnlLine.Correction or
           ItemJnlLine.Adjustment
        then
            exit(true);

        if ItemJournalTemplate.Get(ItemJnlLine."Journal Template Name") then
            if ItemJournalTemplate.Type = ItemJournalTemplate.Type::Revaluation then
                exit(true);

        GetUserSetup;
        if not UserSetup."Check Whse. Net Change Temp." then
            exit(true);

        exit(
          CheckUserSetupLine(
            UserSetup."User ID",
            UserSetupLine.Type::"Whse. Net Change Templates",
            ItemJnlLine."Whse. Net Change Template"));
    end;

    [Scope('OnPrem')]
    procedure UserCheckAllowed()
    begin
        // Used for licence check only
    end;

    [Scope('OnPrem')]
    procedure CheckReleasLocQuantityIncrease(LocationCode: Code[10]): Boolean
    var
        UserSetupLine: Record "User Setup Line";
    begin
        GetUserSetup;
        if not UserSetup."Check Release Location Code" then
            exit(true);

        if Item.IsNonInventoriableType() then
            exit(true);

        exit(CheckUserSetupLine(UserSetup."User ID", UserSetupLine.Type::"Release Location (quantity increase)", LocationCode));
    end;

    [Scope('OnPrem')]
    procedure CheckReleasLocQuantityDecrease(LocationCode: Code[10]): Boolean
    var
        UserSetupLine: Record "User Setup Line";
    begin
        GetUserSetup;
        if not UserSetup."Check Release Location Code" then
            exit(true);

        if Item.IsNonInventoriableType() then
            exit(true);

        exit(CheckUserSetupLine(UserSetup."User ID", UserSetupLine.Type::"Release Location (quantity decrease)", LocationCode));
    end;

    local procedure CheckUserSetupLine(UserCode: Code[50]; Type: Option; CodeName: Code[20]): Boolean
    var
        UserSetupLine: Record "User Setup Line";
    begin
        UserSetupLine.SetRange("User ID", UserCode);
        UserSetupLine.SetRange(Type, Type);
        UserSetupLine.SetRange("Code / Name", CodeName);
        exit(not UserSetupLine.IsEmpty)
    end;

    [Scope('OnPrem')]
    procedure IsCheckAllowed(): Boolean
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get;
        exit(GLSetup."User Checks Allowed");
    end;

    procedure SetItem(ItemNo: Code[20])
    begin
        if not Item.Get(ItemNo) then
            Item.Init();
    end;

    [EventSubscriber(ObjectType::Table, 7311, 'OnCheckWhseJournalTemplateUserRestrictions', '', false, false)]
    [Scope('OnPrem')]
    procedure CheckWhseJournalTemplateUserRestrictions(JournalTemplateName: Code[10])
    var
        DummyUserSetupLine: Record "User Setup Line";
    begin
        CheckJournalTemplate(DummyUserSetupLine.Type::"Whse. Journal", JournalTemplateName);
    end;

    [EventSubscriber(ObjectType::Table, 7326, 'OnCheckWhseWorksheetTemplateUserRestrictions', '', false, false)]
    [Scope('OnPrem')]
    procedure CheckWhseWorksheetTemplateUserRestrictions(WorksheetTemplateName: Code[10])
    var
        DummyUserSetupLine: Record "User Setup Line";
    begin
        CheckJournalTemplate(DummyUserSetupLine.Type::"Whse. Worksheet", WorksheetTemplateName);
    end;

    [EventSubscriber(ObjectType::Table, 81, 'OnCheckGenJournalTemplateUserRestrictions', '', false, false)]
    [Scope('OnPrem')]
    procedure CheckGenJournalTemplateUserRestrictions(JournalTemplateName: Code[10])
    var
        DummyUserSetupLine: Record "User Setup Line";
    begin
        CheckJournalTemplate(DummyUserSetupLine.Type::"General Journal", JournalTemplateName);
    end;

    [EventSubscriber(ObjectType::Table, 83, 'OnCheckItemJournalTemplateUserRestrictions', '', false, false)]
    [Scope('OnPrem')]
    procedure CheckItemJournalTemplateUserRestrictions(JournalTemplateName: Code[10])
    var
        DummyUserSetupLine: Record "User Setup Line";
    begin
        CheckJournalTemplate(DummyUserSetupLine.Type::"Item Journal", JournalTemplateName);
    end;

    [EventSubscriber(ObjectType::Table, 207, 'OnCheckResJournalTemplateUserRestrictions', '', false, false)]
    [Scope('OnPrem')]
    procedure CheckResJournalTemplateUserRestrictions(JournalTemplateName: Code[10])
    var
        DummyUserSetupLine: Record "User Setup Line";
    begin
        CheckJournalTemplate(DummyUserSetupLine.Type::"Resource Journal", JournalTemplateName);
    end;

    [EventSubscriber(ObjectType::Table, 246, 'OnCheckReqWorksheetTemplateUserRestrictions', '', false, false)]
    [Scope('OnPrem')]
    procedure CheckReqJournalTemplateUserRestrictions(WorksheetTemplateName: Code[10])
    var
        DummyUserSetupLine: Record "User Setup Line";
    begin
        CheckJournalTemplate(DummyUserSetupLine.Type::"Req. Worksheet", WorksheetTemplateName);
    end;

    [EventSubscriber(ObjectType::Table, 256, 'OnCheckVATStmtTemplateUserRestrictions', '', false, false)]
    [Scope('OnPrem')]
    procedure CheckVATStmtTemplateUserRestrictions(StatementTemplateName: Code[10])
    var
        DummyUserSetupLine: Record "User Setup Line";
    begin
        CheckJournalTemplate(DummyUserSetupLine.Type::"VAT Statement", StatementTemplateName);
    end;

    [EventSubscriber(ObjectType::Table, 263, 'OnCheckIntrastatJnlTemplateUserRestrictions', '', false, false)]
    [Scope('OnPrem')]
    procedure CheckIntrastatJnlTemplateUserRestrictions(JournalTemplateName: Code[10])
    var
        DummyUserSetupLine: Record "User Setup Line";
    begin
        CheckJournalTemplate(DummyUserSetupLine.Type::"Intrastat Journal", JournalTemplateName);
    end;

    [EventSubscriber(ObjectType::Table, 210, 'OnCheckJobJournalTemplateUserRestrictions', '', false, false)]
    [Scope('OnPrem')]
    procedure CheckJobJournalTemplateUserRestrictions(JournalTemplateName: Code[10])
    var
        DummyUserSetupLine: Record "User Setup Line";
    begin
        CheckJournalTemplate(DummyUserSetupLine.Type::"Job Journal", JournalTemplateName);
    end;

    [EventSubscriber(ObjectType::Table, 5621, 'OnCheckFAJournalLineUserRestrictions', '', false, false)]
    [Scope('OnPrem')]
    procedure CheckFAJournalTemplateUserRestrictions(JournalTemplateName: Code[10])
    var
        DummyUserSetupLine: Record "User Setup Line";
    begin
        CheckJournalTemplate(DummyUserSetupLine.Type::"FA Journal", JournalTemplateName);
    end;

    [EventSubscriber(ObjectType::Table, 5624, 'OnCheckFAReclassJournalTemplateUserRestrictions', '', false, false)]
    [Scope('OnPrem')]
    procedure CheckFAReclasJournallTemplateUserRestrictions(JournalTemplateName: Code[10])
    var
        DummyUserSetupLine: Record "User Setup Line";
    begin
        CheckJournalTemplate(DummyUserSetupLine.Type::"FA Reclass. Journal", JournalTemplateName);
    end;

    [EventSubscriber(ObjectType::Table, 5635, 'OnCheckInsuranceJournalTemplateUserRestrictions', '', false, false)]
    [Scope('OnPrem')]
    procedure CheckInsuranceJournallTemplateUserRestrictions(JournalTemplateName: Code[10])
    var
        DummyUserSetupLine: Record "User Setup Line";
    begin
        CheckJournalTemplate(DummyUserSetupLine.Type::"Insurance Journal", JournalTemplateName);
    end;

    [EventSubscriber(ObjectType::Page, 700, 'OnDrillDownSource', '', false, false)]
    local procedure OnErrorMessageDrillDown(ErrorMessage: Record "Error Message"; SourceFieldNo: Integer; var IsHandled: Boolean)
    var
        CheckDimensions: Codeunit "Check Dimensions";
    begin
        if not IsHandled then
            if (ErrorMessage."Table Number" = DATABASE::"User Setup") and
               (ErrorMessage."Field Number" = UserSetup.FieldNo("Check Dimension Values"))
            then
                case SourceFieldNo of
                    ErrorMessage.FieldNo("Context Record ID"):
                        IsHandled := CheckDimensions.ShowContextDimensions(ErrorMessage."Context Record ID");
                    ErrorMessage.FieldNo("Record ID"):
                        begin
                            GetUserSetup;
                            SelectDimensionsToCheck(UserSetup);
                            IsHandled := true;
                        end;
                end;
    end;
}

