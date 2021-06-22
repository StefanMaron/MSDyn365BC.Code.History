codeunit 230 GenJnlManagement
{
    Permissions = TableData "Gen. Journal Template" = imd,
                  TableData "Gen. Journal Batch" = imd;

    trigger OnRun()
    begin
    end;

    var
        Text000: Label 'Fixed Asset G/L Journal';
        Text001: Label '%1 journal';
        Text002: Label 'RECURRING';
        Text003: Label 'Recurring General Journal';
        Text004: Label 'DEFAULT';
        Text005: Label 'Default Journal';
        LastGenJnlLine: Record "Gen. Journal Line";
        OpenFromBatch: Boolean;

    procedure TemplateSelection(PageID: Integer; PageTemplate: Enum "Gen. Journal Template Type"; RecurringJnl: Boolean; var GenJnlLine: Record "Gen. Journal Line"; var JnlSelected: Boolean)
    var
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlTemplateType: Option;
    begin
        JnlSelected := true;

        GenJnlTemplate.Reset();
        GenJnlTemplate.SetRange("Page ID", PageID);
        GenJnlTemplate.SetRange(Recurring, RecurringJnl);
        if not RecurringJnl then
            GenJnlTemplate.SetRange(Type, PageTemplate);

        GenJnlTemplateType := PageTemplate.AsInteger();
        OnTemplateSelectionSetFilter(GenJnlTemplate, GenJnlTemplateType, RecurringJnl, PageID);
        PageTemplate := "Gen. Journal Template Type".FromInteger(GenJnlTemplateType);

        JnlSelected := FindTemplateFromSelection(GenJnlTemplate, PageTemplate, RecurringJnl);

        if JnlSelected then begin
            GenJnlLine.FilterGroup := 2;
            GenJnlLine.SetRange("Journal Template Name", GenJnlTemplate.Name);
            GenJnlLine.FilterGroup := 0;
            if OpenFromBatch then begin
                GenJnlLine."Journal Template Name" := '';
                PAGE.Run(GenJnlTemplate."Page ID", GenJnlLine);
            end;
        end;

        OnAfterTemplateSelection(GenJnlTemplate, GenJnlLine, JnlSelected, OpenFromBatch, RecurringJnl);
    end;

    procedure TemplateSelectionFromBatch(var GenJnlBatch: Record "Gen. Journal Batch")
    var
        GenJnlTemplate: Record "Gen. Journal Template";
    begin
        OpenFromBatch := true;
        GenJnlTemplate.Get(GenJnlBatch."Journal Template Name");
        GenJnlTemplate.TestField("Page ID");
        GenJnlBatch.TestField(Name);

        OpenJournalPageFromBatch(GenJnlBatch, GenJnlTemplate);
    end;

    local procedure OpenJournalPageFromBatch(var GenJnlBatch: Record "Gen. Journal Batch"; GenJnlTemplate: Record "Gen. Journal Template")
    var
        GenJnlLine: Record "Gen. Journal Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOpenJournalPageFromBatch(GenJnlBatch, GenJnlTemplate, IsHandled);
        if IsHandled then
            exit;

        GenJnlLine.FilterGroup := 2;
        GenJnlLine.SetRange("Journal Template Name", GenJnlTemplate.Name);
        GenJnlLine.FilterGroup := 0;

        GenJnlLine."Journal Template Name" := '';
        GenJnlLine."Journal Batch Name" := GenJnlBatch.Name;
        PAGE.Run(GenJnlTemplate."Page ID", GenJnlLine);
    end;

    procedure OpenJnl(var CurrentJnlBatchName: Code[10]; var GenJnlLine: Record "Gen. Journal Line")
    begin
        OnBeforeOpenJnl(CurrentJnlBatchName, GenJnlLine);

        if (GenJnlLine."Journal Template Name" <> '') and (GenJnlLine.GetFilter("Journal Template Name") = '') then
            CheckTemplateName(GenJnlLine."Journal Template Name", CurrentJnlBatchName)
        else
            CheckTemplateName(GenJnlLine.GetRangeMax("Journal Template Name"), CurrentJnlBatchName);
        GenJnlLine.FilterGroup := 2;
        GenJnlLine.SetRange("Journal Batch Name", CurrentJnlBatchName);
        GenJnlLine.FilterGroup := 0;
    end;

    procedure OpenJnlBatch(var GenJnlBatch: Record "Gen. Journal Batch")
    var
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJnlLine: Record "Gen. Journal Line";
        JnlSelected: Boolean;
    begin
        if GenJnlBatch.GetFilter("Journal Template Name") <> '' then
            exit;
        GenJnlBatch.FilterGroup(2);
        if GenJnlBatch.GetFilter("Journal Template Name") <> '' then begin
            GenJnlBatch.FilterGroup(0);
            exit;
        end;
        GenJnlBatch.FilterGroup(0);

        if not GenJnlBatch.Find('-') then
            for GenJnlTemplate.Type := GenJnlTemplate.Type::General to GenJnlTemplate.Type::Jobs do begin
                GenJnlTemplate.SetRange(Type, GenJnlTemplate.Type);
                if not GenJnlTemplate.FindFirst then
                    TemplateSelection(0, GenJnlTemplate.Type, false, GenJnlLine, JnlSelected);
                if GenJnlTemplate.FindFirst then
                    CheckTemplateName(GenJnlTemplate.Name, GenJnlBatch.Name);
                if GenJnlTemplate.Type = GenJnlTemplate.Type::General then begin
                    GenJnlTemplate.SetRange(Recurring, true);
                    if not GenJnlTemplate.FindFirst then
                        TemplateSelection(0, GenJnlTemplate.Type, true, GenJnlLine, JnlSelected);
                    if GenJnlTemplate.FindFirst then
                        CheckTemplateName(GenJnlTemplate.Name, GenJnlBatch.Name);
                    GenJnlTemplate.SetRange(Recurring);
                end;
            end;

        GenJnlBatch.Find('-');
        JnlSelected := true;
        GenJnlBatch.CalcFields("Template Type", Recurring);
        GenJnlTemplate.SetRange(Recurring, GenJnlBatch.Recurring);
        if not GenJnlBatch.Recurring then
            GenJnlTemplate.SetRange(Type, GenJnlBatch."Template Type");
        if GenJnlBatch.GetFilter("Journal Template Name") <> '' then
            GenJnlTemplate.SetRange(Name, GenJnlBatch.GetFilter("Journal Template Name"));
        case GenJnlTemplate.Count of
            1:
                GenJnlTemplate.FindFirst;
            else
                JnlSelected := PAGE.RunModal(0, GenJnlTemplate) = ACTION::LookupOK;
        end;
        if not JnlSelected then
            Error('');

        GenJnlBatch.FilterGroup(0);
        GenJnlBatch.SetRange("Journal Template Name", GenJnlTemplate.Name);
        GenJnlBatch.FilterGroup(2);
    end;

    procedure IsBatchNoSeriesEmpty(var CurrentJnlBatchName: Code[10]; var GenJnlLine: Record "Gen. Journal Line"): Boolean
    var
        GenJnlBatch: Record "Gen. Journal Batch";
    begin
        if (GenJnlLine."Journal Template Name" <> '') and (GenJnlLine.GetFilter("Journal Template Name") = '') then
            GenJnlBatch.get(GenJnlLine."Journal Template Name", CurrentJnlBatchName)
        else
            if GenJnlBatch.get(GenJnlLine.GetRangeMax("Journal Template Name"), CurrentJnlBatchName) then;
        exit(GenJnlBatch."No. Series" = '');
    end;

    [Scope('OnPrem')]
    procedure CheckTemplateName(CurrentJnlTemplateName: Code[10]; var CurrentJnlBatchName: Code[10])
    var
        GenJnlBatch: Record "Gen. Journal Batch";
    begin
        GenJnlBatch.SetRange("Journal Template Name", CurrentJnlTemplateName);
        if not GenJnlBatch.Get(CurrentJnlTemplateName, CurrentJnlBatchName) then begin
            if not GenJnlBatch.FindFirst then begin
                GenJnlBatch.Init();
                GenJnlBatch."Journal Template Name" := CurrentJnlTemplateName;
                GenJnlBatch.SetupNewBatch;
                GenJnlBatch.Name := Text004;
                GenJnlBatch.Description := Text005;
                GenJnlBatch.Insert(true);
                Commit();
            end;
            CurrentJnlBatchName := GenJnlBatch.Name
        end;
    end;

    procedure CheckName(CurrentJnlBatchName: Code[10]; var GenJnlLine: Record "Gen. Journal Line")
    var
        GenJnlBatch: Record "Gen. Journal Batch";
    begin
        GenJnlBatch.Get(GenJnlLine.GetRangeMax("Journal Template Name"), CurrentJnlBatchName);
    end;

    [Scope('OnPrem')]
    procedure CheckCurrencyCode(CurrencyCode: Code[10])
    var
        Currency: Record Currency;
    begin
        Currency.Get(CurrencyCode);
    end;

    procedure SetName(CurrentJnlBatchName: Code[10]; var GenJnlLine: Record "Gen. Journal Line")
    begin
        GenJnlLine.FilterGroup := 2;
        GenJnlLine.SetRange("Journal Batch Name", CurrentJnlBatchName);
        GenJnlLine.FilterGroup := 0;
        OnAfterSetName(GenJnlLine, CurrentJnlBatchName);
        if GenJnlLine.Find('-') then;
    end;

    procedure SetJournalSimplePageModePreference(SetToSimpleMode: Boolean; PageIdToSet: Integer)
    var
        JournalUserPreferences: Record "Journal User Preferences";
        IsHandled: Boolean;
    begin
        // sets journal page preference for a page
        // preference set to simple page if SetToSimpleMode is true; else set to classic mode

        IsHandled := false;
        OnBeforeSetJournalSimplePageModePreference(SetToSimpleMode, PageIdToSet, IsHandled);
        if IsHandled then
            exit;

        JournalUserPreferences.Reset();
        JournalUserPreferences.SetFilter("User ID", '%1', UserSecurityId);
        JournalUserPreferences.SetFilter("Page ID", '%1', PageIdToSet);
        if JournalUserPreferences.FindFirst then begin
            JournalUserPreferences."Is Simple View" := SetToSimpleMode;
            JournalUserPreferences.Modify();
        end else begin
            Clear(JournalUserPreferences);
            JournalUserPreferences."Page ID" := PageIdToSet;
            JournalUserPreferences."Is Simple View" := SetToSimpleMode;
            JournalUserPreferences."User ID" := UserSecurityId;
            JournalUserPreferences.Insert();
        end;
    end;

    procedure GetJournalSimplePageModePreference(PageIdToCheck: Integer): Boolean
    var
        JournalUserPreferences: Record "Journal User Preferences";
    begin
        // Get journal page mode preference for a page; By defaults this returns FALSE unless a preference
        // is set
        JournalUserPreferences.Reset();
        JournalUserPreferences.SetFilter("User ID", '%1', UserSecurityId);
        JournalUserPreferences.SetFilter("Page ID", '%1', PageIdToCheck);
        if JournalUserPreferences.FindFirst then
            exit(JournalUserPreferences."Is Simple View");
        exit(false);
    end;

    procedure GetLastViewedJournalBatchName(PageIdToCheck: Integer): Code[10]
    var
        JournalUserPreferences: Record "Journal User Preferences";
    begin
        JournalUserPreferences.Reset();
        JournalUserPreferences.SetFilter("User ID", '%1', UserSecurityId);
        JournalUserPreferences.SetFilter("Page ID", '%1', PageIdToCheck);
        if JournalUserPreferences.FindFirst then
            exit(JournalUserPreferences."Journal Batch Name");
        exit('');
    end;

    procedure SetLastViewedJournalBatchName(PageIdToCheck: Integer; GenJnlBatch: Code[10])
    var
        JournalUserPreferences: Record "Journal User Preferences";
    begin
        JournalUserPreferences.Reset();
        JournalUserPreferences.SetFilter("User ID", '%1', UserSecurityId);
        JournalUserPreferences.SetFilter("Page ID", '%1', PageIdToCheck);
        if JournalUserPreferences.FindFirst then begin
            JournalUserPreferences."Journal Batch Name" := GenJnlBatch;
            JournalUserPreferences.Modify();
        end;
    end;

    procedure LookupName(var CurrentJnlBatchName: Code[10]; var GenJnlLine: Record "Gen. Journal Line")
    var
        GenJnlBatch: Record "Gen. Journal Batch";
    begin
        Commit();
        GenJnlBatch."Journal Template Name" := GenJnlLine.GetRangeMax("Journal Template Name");
        GenJnlBatch.Name := GenJnlLine.GetRangeMax("Journal Batch Name");
        GenJnlBatch.FilterGroup(2);
        GenJnlBatch.SetRange("Journal Template Name", GenJnlBatch."Journal Template Name");
        GenJnlBatch.FilterGroup(0);
        OnBeforeLookupName(GenJnlBatch);
        if PAGE.RunModal(0, GenJnlBatch) = ACTION::LookupOK then begin
            CurrentJnlBatchName := GenJnlBatch.Name;
            SetName(CurrentJnlBatchName, GenJnlLine);
        end;
    end;

    procedure GetAccounts(var GenJnlLine: Record "Gen. Journal Line"; var AccName: Text[100]; var BalAccName: Text[100])
    var
        GLAcc: Record "G/L Account";
        Cust: Record Customer;
        Vend: Record Vendor;
        BankAcc: Record "Bank Account";
        FA: Record "Fixed Asset";
        IC: Record "IC Partner";
        Employee: Record Employee;
    begin
        if (GenJnlLine."Account Type" <> LastGenJnlLine."Account Type") or
           (GenJnlLine."Account No." <> LastGenJnlLine."Account No.")
        then begin
            AccName := '';
            if GenJnlLine."Account No." <> '' then
                case GenJnlLine."Account Type" of
                    GenJnlLine."Account Type"::"G/L Account":
                        if GLAcc.Get(GenJnlLine."Account No.") then
                            AccName := GLAcc.Name;
                    GenJnlLine."Account Type"::Customer:
                        if Cust.Get(GenJnlLine."Account No.") then
                            AccName := Cust.Name;
                    GenJnlLine."Account Type"::Vendor:
                        if Vend.Get(GenJnlLine."Account No.") then
                            AccName := Vend.Name;
                    GenJnlLine."Account Type"::"Bank Account":
                        if BankAcc.Get(GenJnlLine."Account No.") then
                            AccName := BankAcc.Name;
                    GenJnlLine."Account Type"::"Fixed Asset":
                        if FA.Get(GenJnlLine."Account No.") then
                            AccName := FA.Description;
                    GenJnlLine."Account Type"::"IC Partner":
                        if IC.Get(GenJnlLine."Account No.") then
                            AccName := IC.Name;
                    GenJnlLine."Account Type"::Employee:
                        if Employee.Get(GenJnlLine."Account No.") then
                            AccName := Employee."First Name" + ' ' + Employee."Last Name";
                end;
        end;

        if (GenJnlLine."Bal. Account Type" <> LastGenJnlLine."Bal. Account Type") or
           (GenJnlLine."Bal. Account No." <> LastGenJnlLine."Bal. Account No.")
        then begin
            BalAccName := '';
            if GenJnlLine."Bal. Account No." <> '' then
                case GenJnlLine."Bal. Account Type" of
                    GenJnlLine."Bal. Account Type"::"G/L Account":
                        if GLAcc.Get(GenJnlLine."Bal. Account No.") then
                            BalAccName := GLAcc.Name;
                    GenJnlLine."Bal. Account Type"::Customer:
                        if Cust.Get(GenJnlLine."Bal. Account No.") then
                            BalAccName := Cust.Name;
                    GenJnlLine."Bal. Account Type"::Vendor:
                        if Vend.Get(GenJnlLine."Bal. Account No.") then
                            BalAccName := Vend.Name;
                    GenJnlLine."Bal. Account Type"::"Bank Account":
                        if BankAcc.Get(GenJnlLine."Bal. Account No.") then
                            BalAccName := BankAcc.Name;
                    GenJnlLine."Bal. Account Type"::"Fixed Asset":
                        if FA.Get(GenJnlLine."Bal. Account No.") then
                            BalAccName := FA.Description;
                    GenJnlLine."Bal. Account Type"::"IC Partner":
                        if IC.Get(GenJnlLine."Bal. Account No.") then
                            BalAccName := IC.Name;
                end;
        end;

        OnAfterGetAccounts(GenJnlLine, AccName, BalAccName);

        LastGenJnlLine := GenJnlLine;
    end;

    procedure CalcBalance(var GenJnlLine: Record "Gen. Journal Line"; LastGenJnlLine: Record "Gen. Journal Line"; var Balance: Decimal; var TotalBalance: Decimal; var ShowBalance: Boolean; var ShowTotalBalance: Boolean)
    var
        TempGenJnlLine: Record "Gen. Journal Line";
    begin
        TempGenJnlLine.CopyFilters(GenJnlLine);
        if CurrentClientType in [CLIENTTYPE::SOAP, CLIENTTYPE::OData, CLIENTTYPE::ODataV4, CLIENTTYPE::Api] then
            ShowTotalBalance := false
        else
            ShowTotalBalance := TempGenJnlLine.CalcSums("Balance (LCY)");

        if ShowTotalBalance then begin
            TotalBalance := TempGenJnlLine."Balance (LCY)";
            if GenJnlLine."Line No." = 0 then
                TotalBalance := TotalBalance + LastGenJnlLine."Balance (LCY)";
        end;

        if GenJnlLine."Line No." <> 0 then begin
            TempGenJnlLine.SetRange("Line No.", 0, GenJnlLine."Line No.");
            ShowBalance := TempGenJnlLine.CalcSums("Balance (LCY)");
            if ShowBalance then
                Balance := TempGenJnlLine."Balance (LCY)";
        end else begin
            TempGenJnlLine.SetRange("Line No.", 0, LastGenJnlLine."Line No.");
            ShowBalance := TempGenJnlLine.CalcSums("Balance (LCY)");
            if ShowBalance then begin
                Balance := TempGenJnlLine."Balance (LCY)";
                TempGenJnlLine.CopyFilters(GenJnlLine);
                TempGenJnlLine := LastGenJnlLine;
                if TempGenJnlLine.Next = 0 then
                    Balance := Balance + LastGenJnlLine."Balance (LCY)";
            end;
        end;
        if CurrentClientType in [CLIENTTYPE::SOAP, CLIENTTYPE::OData, CLIENTTYPE::ODataV4, CLIENTTYPE::Api] then
            ShowBalance := false

    end;

    procedure GetAvailableGeneralJournalTemplateName(TemplateName: Code[10]): Code[10]
    var
        GenJnlTemplate: Record "Gen. Journal Template";
        PotentialTemplateName: Code[10];
        PotentialTemplateNameIncrement: Integer;
    begin
        // Make sure proposed value + incrementer will fit in Name field
        if StrLen(TemplateName) > 9 then
            TemplateName := Format(TemplateName, 9);

        GenJnlTemplate.Init();
        PotentialTemplateName := TemplateName;
        PotentialTemplateNameIncrement := 0;

        // Expecting few naming conflicts, but limiting to 10 iterations to avoid possible infinite loop.
        while PotentialTemplateNameIncrement < 10 do begin
            GenJnlTemplate.SetFilter(Name, PotentialTemplateName);
            if GenJnlTemplate.Count = 0 then
                exit(PotentialTemplateName);

            PotentialTemplateNameIncrement := PotentialTemplateNameIncrement + 1;
            PotentialTemplateName := TemplateName + Format(PotentialTemplateNameIncrement);
        end;
    end;

    local procedure FindTemplateFromSelection(var GenJnlTemplate: Record "Gen. Journal Template"; TemplateType: Enum "Gen. Journal Template Type"; RecurringJnl: Boolean) TemplateSelected: Boolean
    begin
        TemplateSelected := true;
        case GenJnlTemplate.Count of
            0:
                begin
                    GenJnlTemplate.Init();
                    GenJnlTemplate.Type := TemplateType;
                    GenJnlTemplate.Recurring := RecurringJnl;
                    if not RecurringJnl then begin
                        GenJnlTemplate.Name :=
                          GetAvailableGeneralJournalTemplateName(Format(GenJnlTemplate.Type, MaxStrLen(GenJnlTemplate.Name)));
                        if TemplateType = GenJnlTemplate.Type::Assets then
                            GenJnlTemplate.Description := Text000
                        else
                            GenJnlTemplate.Description := StrSubstNo(Text001, GenJnlTemplate.Type);
                    end else begin
                        GenJnlTemplate.Name := Text002;
                        GenJnlTemplate.Description := Text003;
                    end;
                    GenJnlTemplate.Validate(Type);
                    OnFindTemplateFromSelectionOnBeforeGenJnlTemplateInsert(GenJnlTemplate);
                    GenJnlTemplate.Insert();
                    Commit();
                end;
            1:
                GenJnlTemplate.FindFirst;
            else
                TemplateSelected := PAGE.RunModal(0, GenJnlTemplate) = ACTION::LookupOK;
        end;
    end;

    [Scope('OnPrem')]
    procedure TemplateSelectionSimple(var GenJnlTemplate: Record "Gen. Journal Template"; TemplateType: Enum "Gen. Journal Template Type"; RecurringJnl: Boolean): Boolean
    begin
        GenJnlTemplate.Reset();
        GenJnlTemplate.SetRange(Type, TemplateType);
        GenJnlTemplate.SetRange(Recurring, RecurringJnl);
        exit(FindTemplateFromSelection(GenJnlTemplate, TemplateType, RecurringJnl));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetAccounts(var GenJournalLine: Record "Gen. Journal Line"; var AccName: Text[100]; var BalAccName: Text[100])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetName(var GenJournalLine: Record "Gen. Journal Line"; CurrentJnlBatchName: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTemplateSelection(var GenJnlTemplate: Record "Gen. Journal Template"; var GenJnlLine: Record "Gen. Journal Line"; var JnlSelected: Boolean; var OpenFromBatch: Boolean; RecurringJnl: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupName(var GenJnlBatch: Record "Gen. Journal Batch")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetJournalSimplePageModePreference(var SetToSimpleMode: Boolean; PageIdToSet: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOpenJnl(var CurrentJnlBatchName: Code[10]; var GenJnlLine: Record "Gen. Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOpenJournalPageFromBatch(var GenJnlBatch: Record "Gen. Journal Batch"; var GenJnlTemplate: Record "Gen. Journal Template"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTemplateSelectionSetFilter(var GenJnlTemplate: Record "Gen. Journal Template"; var PageTemplate: Option; var RecurringJnl: Boolean; PageId: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindTemplateFromSelectionOnBeforeGenJnlTemplateInsert(var GenJnlTemplate: Record "Gen. Journal Template")
    begin
    end;
}

