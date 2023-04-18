#if not CLEAN22
codeunit 350 IntraJnlManagement
{
    Permissions = TableData "Intrastat Jnl. Template" = rimd,
                  TableData "Intrastat Jnl. Batch" = rimd;
    ObsoleteState = Pending;
    ObsoleteTag = '22.0';
    ObsoleteReason = 'Intrastat related functionalities are moved to Intrastat extensions.';

    trigger OnRun()
    begin
    end;

    var
        Text000: Label 'INTRASTAT';
        Text001: Label 'Intrastat Journal';
        Text002: Label 'DEFAULT';
        Text003: Label 'Default Journal';
        OpenFromBatch: Boolean;
        AdvChecklistErr: Label 'There are one or more errors. For details, see the journal error FactBox.';

    procedure TemplateSelection(PageID: Integer; var IntrastatJnlLine: Record "Intrastat Jnl. Line"; var JnlSelected: Boolean)
    var
        IntraJnlTemplate: Record "Intrastat Jnl. Template";
    begin
        JnlSelected := true;

        IntraJnlTemplate.Reset();
        IntraJnlTemplate.SetRange("Page ID", PageID);

        case IntraJnlTemplate.Count of
            0:
                begin
                    IntraJnlTemplate.Init();
                    IntraJnlTemplate.Name := Text000;
                    IntraJnlTemplate.Description := Text001;
                    IntraJnlTemplate.Validate("Page ID");
                    IntraJnlTemplate.Insert();
                    Commit();
                end;
            1:
                IntraJnlTemplate.FindFirst();
            else
                JnlSelected := PAGE.RunModal(0, IntraJnlTemplate) = ACTION::LookupOK;
        end;
        if JnlSelected then begin
            IntrastatJnlLine.FilterGroup(2);
            IntrastatJnlLine.SetRange("Journal Template Name", IntraJnlTemplate.Name);
            IntrastatJnlLine.FilterGroup(0);
            if OpenFromBatch then begin
                IntrastatJnlLine."Journal Template Name" := '';
                PAGE.Run(IntraJnlTemplate."Page ID", IntrastatJnlLine);
            end;
        end;
    end;

    procedure TemplateSelectionFromBatch(var IntrastatJnlBatch: Record "Intrastat Jnl. Batch")
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        IntraJnlTemplate: Record "Intrastat Jnl. Template";
    begin
        OpenFromBatch := true;
        IntraJnlTemplate.Get(IntrastatJnlBatch."Journal Template Name");
        IntraJnlTemplate.TestField("Page ID");
        IntrastatJnlBatch.TestField(Name);

        IntrastatJnlLine.FilterGroup := 2;
        IntrastatJnlLine.SetRange("Journal Template Name", IntraJnlTemplate.Name);
        IntrastatJnlLine.FilterGroup := 0;

        IntrastatJnlLine."Journal Template Name" := '';
        IntrastatJnlLine."Journal Batch Name" := IntrastatJnlBatch.Name;
        PAGE.Run(IntraJnlTemplate."Page ID", IntrastatJnlLine);
    end;

    procedure OpenJnl(var CurrentJnlBatchName: Code[10]; var IntrastatJnlLine: Record "Intrastat Jnl. Line")
    begin
        OnBeforeOpenJnl(CurrentJnlBatchName, IntrastatJnlLine);

        CheckTemplateName(IntrastatJnlLine.GetRangeMax("Journal Template Name"), CurrentJnlBatchName);
        IntrastatJnlLine.FilterGroup(2);
        IntrastatJnlLine.SetRange("Journal Batch Name", CurrentJnlBatchName);
        IntrastatJnlLine.FilterGroup(0);
    end;

    procedure OpenJnlBatch(var IntrastatJnlBatch: Record "Intrastat Jnl. Batch")
    var
        IntraJnlTemplate: Record "Intrastat Jnl. Template";
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
        JnlSelected: Boolean;
    begin
        if IntrastatJnlBatch.GetFilter("Journal Template Name") <> '' then
            exit;
        IntrastatJnlBatch.FilterGroup(2);
        if IntrastatJnlBatch.GetFilter("Journal Template Name") <> '' then begin
            IntrastatJnlBatch.FilterGroup(0);
            exit;
        end;
        IntrastatJnlBatch.FilterGroup(0);

        if not IntrastatJnlBatch.Find('-') then begin
            if not IntraJnlTemplate.FindFirst() then
                TemplateSelection(0, IntrastatJnlLine, JnlSelected);
            if IntraJnlTemplate.FindFirst() then
                CheckTemplateName(IntraJnlTemplate.Name, IntrastatJnlBatch.Name);
        end;
        IntrastatJnlBatch.Find('-');
        JnlSelected := true;
        if IntrastatJnlBatch.GetFilter("Journal Template Name") <> '' then
            IntraJnlTemplate.SetRange(Name, IntrastatJnlBatch.GetFilter("Journal Template Name"));
        case IntraJnlTemplate.Count of
            1:
                IntraJnlTemplate.FindFirst();
            else
                JnlSelected := PAGE.RunModal(0, IntraJnlTemplate) = ACTION::LookupOK;
        end;
        if not JnlSelected then
            Error('');

        IntrastatJnlBatch.FilterGroup(0);
        IntrastatJnlBatch.SetRange("Journal Template Name", IntraJnlTemplate.Name);
        IntrastatJnlBatch.FilterGroup(2);
    end;

    local procedure CheckTemplateName(CurrentJnlTemplateName: Code[10]; var CurrentJnlBatchName: Code[10])
    var
        IntraJnlTemplate: Record "Intrastat Jnl. Template";
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckTemplateName(CurrentJnlTemplateName, CurrentJnlBatchName, IsHandled);
        if IsHandled then
            exit;

        IntrastatJnlBatch.SetRange("Journal Template Name", CurrentJnlTemplateName);
        if not IntrastatJnlBatch.Get(CurrentJnlTemplateName, CurrentJnlBatchName) then begin
            if not IntrastatJnlBatch.FindFirst() then begin
                IntraJnlTemplate.Get(CurrentJnlTemplateName);
                IntrastatJnlBatch.Init();
                IntrastatJnlBatch."Journal Template Name" := IntraJnlTemplate.Name;
                IntrastatJnlBatch.Name := Text002;
                IntrastatJnlBatch.Description := Text003;
                IntrastatJnlBatch.Insert();
                Commit();
            end;
            CurrentJnlBatchName := IntrastatJnlBatch.Name;
        end;
    end;

    procedure CheckName(CurrentJnlBatchName: Code[10]; var IntrastatJnlLine: Record "Intrastat Jnl. Line")
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
    begin
        IntrastatJnlBatch.Get(IntrastatJnlLine.GetRangeMax("Journal Template Name"), CurrentJnlBatchName);
    end;

    procedure SetName(CurrentJnlBatchName: Code[10]; var IntrastatJnlLine: Record "Intrastat Jnl. Line")
    begin
        IntrastatJnlLine.FilterGroup(2);
        IntrastatJnlLine.SetRange("Journal Batch Name", CurrentJnlBatchName);
        IntrastatJnlLine.FilterGroup(0);
        if IntrastatJnlLine.Find('-') then;
    end;

    procedure LookupName(CurrentJnlTemplateName: Code[10]; CurrentJnlBatchName: Code[10]; var EntrdJnlBatchName: Text[10]): Boolean
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
    begin
        IntrastatJnlBatch."Journal Template Name" := CurrentJnlTemplateName;
        IntrastatJnlBatch.Name := CurrentJnlBatchName;
        IntrastatJnlBatch.FilterGroup(2);
        IntrastatJnlBatch.SetRange("Journal Template Name", CurrentJnlTemplateName);
        IntrastatJnlBatch.FilterGroup(0);
        if PAGE.RunModal(0, IntrastatJnlBatch) <> ACTION::LookupOK then
            exit(false);

        EntrdJnlBatchName := IntrastatJnlBatch.Name;
        exit(true);
    end;

    procedure CalcStatisticalValue(var IntrastatJnlLine: Record "Intrastat Jnl. Line"; LastIntrastatJnlLine: Record "Intrastat Jnl. Line"; var StatisticalValue: Decimal; var TotalStatisticalValue: Decimal; var ShowStatisticalValue: Boolean; var ShowTotalStatisticalValue: Boolean)
    var
        TempIntrastatJnlLine: Record "Intrastat Jnl. Line";
        TempIntrastatJnlLine2: Record "Intrastat Jnl. Line";
    begin
        TempIntrastatJnlLine.CopyFilters(IntrastatJnlLine);

        if TempIntrastatJnlLine.CalcSums("Statistical Value") then begin
            if IntrastatJnlLine."Line No." <> 0 then // 0 = New record
                TotalStatisticalValue := TempIntrastatJnlLine."Statistical Value"
            else
                TotalStatisticalValue := TempIntrastatJnlLine."Statistical Value" + LastIntrastatJnlLine."Statistical Value";

            ShowTotalStatisticalValue := true;
        end else
            ShowTotalStatisticalValue := false;

        if IntrastatJnlLine."Line No." <> 0 then begin // 0 = New record
            TempIntrastatJnlLine.SetFilter("Line No.", '<=%1', IntrastatJnlLine."Line No.");
            if TempIntrastatJnlLine.CalcSums("Statistical Value") then begin
                StatisticalValue := TempIntrastatJnlLine."Statistical Value";
                ShowStatisticalValue := true;
            end else
                ShowStatisticalValue := false;
        end else begin
            TempIntrastatJnlLine.SetFilter("Line No.", '<=%1', LastIntrastatJnlLine."Line No.");
            if TempIntrastatJnlLine.CalcSums("Statistical Value") then begin
                TempIntrastatJnlLine2.CopyFilters(IntrastatJnlLine);
                TempIntrastatJnlLine2 := LastIntrastatJnlLine;
                if TempIntrastatJnlLine2.Next() <> 0 then
                    StatisticalValue := TempIntrastatJnlLine."Statistical Value"
                else
                    StatisticalValue := TempIntrastatJnlLine."Statistical Value" + LastIntrastatJnlLine."Statistical Value";

                ShowStatisticalValue := true;
            end else
                ShowStatisticalValue := false;
        end;
    end;

    procedure ValidateReportWithAdvancedChecklist(IntrastatJnlLine: Record "Intrastat Jnl. Line"; ReportId: Integer; ThrowError: Boolean): Boolean
    var
        AdvancedIntrastatChecklist: Record "Advanced Intrastat Checklist";
    begin
        exit(ValidateObjectWithAdvancedChecklist(IntrastatJnlLine, AdvancedIntrastatChecklist."Object Type"::Report, ReportId, ThrowError));
    end;

    procedure ValidateCodeunitWithAdvancedChecklist(IntrastatJnlLine: Record "Intrastat Jnl. Line"; CodeunitId: Integer; ThrowError: Boolean): Boolean
    var
        AdvancedIntrastatChecklist: Record "Advanced Intrastat Checklist";
    begin
        exit(ValidateObjectWithAdvancedChecklist(IntrastatJnlLine, AdvancedIntrastatChecklist."Object Type"::Codeunit, CodeunitId, ThrowError));
    end;

    procedure IsAdvancedChecklistReportField(ReportId: Integer; FieldNo: Integer; FilterExpression: Text): Boolean
    var
        AdvancedIntrastatChecklist: Record "Advanced Intrastat Checklist";
    begin
        AdvancedIntrastatChecklist.SetRange("Object Type", AdvancedIntrastatChecklist."Object Type"::Report);
        AdvancedIntrastatChecklist.SetRange("Object Id", ReportId);
        AdvancedIntrastatChecklist.SetRange("Field No.", FieldNo);
        AdvancedIntrastatChecklist.SetRange("Filter Expression", FilterExpression);
        exit(not AdvancedIntrastatChecklist.IsEmpty());
    end;

    local procedure ValidateObjectWithAdvancedChecklist(IntrastatJnlLine: Record "Intrastat Jnl. Line"; ObjectType: Option; ObjectId: Integer; ThrowError: Boolean): Boolean
    var
        ErrorMessage: Record "Error Message";
        AdvancedIntrastatChecklist: Record "Advanced Intrastat Checklist";
        AnyError: Boolean;
    begin
        ChecklistSetBatchContext(ErrorMessage, IntrastatJnlLine);
        AdvancedIntrastatChecklist.SetRange("Object Type", ObjectType);
        AdvancedIntrastatChecklist.SetRange("Object Id", ObjectId);
        if AdvancedIntrastatChecklist.FindSet() then
            repeat
                if AdvancedIntrastatChecklist.LinePassesFilterExpression(IntrastatJnlLine) then
                    AnyError :=
                      AnyError or
                      (ErrorMessage.LogIfEmpty(
                         IntrastatJnlLine, AdvancedIntrastatChecklist."Field No.", ErrorMessage."Message Type"::Error) <> 0);
            until AdvancedIntrastatChecklist.Next() = 0;

        if AnyError and ThrowError then
            ThrowJournalBatchError();

        exit(not AnyError);
    end;

    procedure ChecklistClearBatchErrors(IntrastatJnlBatch: Record "Intrastat Jnl. Batch")
    var
        ErrorMessage: Record "Error Message";
    begin
        ErrorMessage.SetContext(IntrastatJnlBatch);
        ErrorMessage.ClearLog();
    end;

    local procedure ChecklistSetBatchContext(var ErrorMessage: Record "Error Message"; IntrastatJnlLine: Record "Intrastat Jnl. Line")
    var
        IntrastatJnlBatch: Record "Intrastat Jnl. Batch";
    begin
        IntrastatJnlBatch."Journal Template Name" := IntrastatJnlLine."Journal Template Name";
        IntrastatJnlBatch.Name := IntrastatJnlLine."Journal Batch Name";
        ErrorMessage.SetContext(IntrastatJnlBatch);
    end;

    procedure CreateDefaultAdvancedIntrastatSetup()
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        CreateAdvancedChecklistSetupCommonFields(Report::"Intrastat - Checklist");
        CreateAdvancedChecklistSetupCommonFields(Report::"Intrastat - Form");
        CreateAdvancedChecklistSetupCommonFields(Report::"Intrastat - Make Disk Tax Auth");

        CreateAdvancedChecklistFieldSetup(Report::"Intrastat - Checklist", IntrastatJnlLine.FieldNo(Quantity), '');
        CreateAdvancedChecklistFieldSetup(Report::"Intrastat - Form", IntrastatJnlLine.FieldNo(Quantity), 'Supplementary Units: True');
        CreateAdvancedChecklistFieldSetup(Report::"Intrastat - Make Disk Tax Auth", IntrastatJnlLine.FieldNo(Quantity), 'Supplementary Units: True');

        OnAfterCreateDefaultAdvancedIntrastatSetup();
    end;

    local procedure CreateAdvancedChecklistSetupCommonFields(ReportId: Integer)
    var
        IntrastatJnlLine: Record "Intrastat Jnl. Line";
    begin
        CreateAdvancedChecklistFieldSetup(ReportId, IntrastatJnlLine.FieldNo("Tariff No."), '');
        CreateAdvancedChecklistFieldSetup(ReportId, IntrastatJnlLine.FieldNo("Country/Region Code"), '');
        CreateAdvancedChecklistFieldSetup(ReportId, IntrastatJnlLine.FieldNo("Transaction Type"), '');
        CreateAdvancedChecklistFieldSetup(ReportId, IntrastatJnlLine.FieldNo("Total Weight"), 'Supplementary Units: False');
        CreateAdvancedChecklistFieldSetup(ReportId, IntrastatJnlLine.FieldNo("Partner VAT ID"), 'Type: Shipment');
        CreateAdvancedChecklistFieldSetup(ReportId, IntrastatJnlLine.FieldNo("Country/Region of Origin Code"), 'Type: Shipment');
    end;

    local procedure CreateAdvancedChecklistFieldSetup(ReportId: Integer; FieldNo: Integer; FilterExpr: Text)
    var
        AdvancedIntrastatChecklist: Record "Advanced Intrastat Checklist";
    begin
        AdvancedIntrastatChecklist.Init();
        AdvancedIntrastatChecklist.Validate("Object Type", AdvancedIntrastatChecklist."Object Type"::Report);
        AdvancedIntrastatChecklist.Validate("Object Id", ReportId);
        AdvancedIntrastatChecklist.Validate("Field No.", FieldNo);
        AdvancedIntrastatChecklist.Validate("Filter Expression", FilterExpr);
        if AdvancedIntrastatChecklist.Insert() then;
    end;

    procedure CheckForJournalBatchError(IntrastatJnlLine: Record "Intrastat Jnl. Line"; ThrowError: Boolean)
    var
        ErrorMessage: Record "Error Message";
    begin
        ChecklistSetBatchContext(ErrorMessage, IntrastatJnlLine);
        if ErrorMessage.HasErrors(false) and ThrowError then
            ThrowJournalBatchError();
    end;

    local procedure ThrowJournalBatchError()
    begin
        Commit();
        Error(AdvChecklistErr);
    end;

    procedure RoundTotalWeight(TotalWeight: Decimal): Decimal
    var
        IsHandled: Boolean;
    begin
        OnBeforeRoundTotalWeight(IsHandled, TotalWeight);
        if IsHandled then
            exit(TotalWeight);

        exit(Round(TotalWeight, 1, '>'));
    end;

    procedure GetCompanyVATRegNo(): Text[50]
    var
        CompanyInformation: Record "Company Information";
        IntrastatSetup: Record "Intrastat Setup";
    begin
        CompanyInformation.Get();
        if not IntrastatSetup.Get() then
            exit(CompanyInformation."VAT Registration No.");
        exit(
          GetVATRegNo(
            CompanyInformation."Country/Region Code", CompanyInformation."VAT Registration No.",
            IntrastatSetup."Company VAT No. on File"));
    end;

    procedure GetVATRegNo(CountryCode: Code[10]; VATRegNo: Text[20]; VATRegNoType: Enum "Intrastat VAT No. On File"): Text[50]
    var
        IntrastatSetup: Record "Intrastat Setup";
        CountryRegion: Record "Country/Region";
    begin
        case VATRegNoType of
            IntrastatSetup."Company VAT No. on File"::"VAT Reg. No.":
                exit(VATRegNo);
            IntrastatSetup."Company VAT No. on File"::"EU Country Code + VAT Reg. No":
                begin
                    CountryRegion.Get(CountryCode);
                    if CountryRegion."EU Country/Region Code" <> '' then
                        CountryCode := CountryRegion."EU Country/Region Code";
                    exit(CountryCode + VATRegNo);
                end;
            IntrastatSetup."Company VAT No. on File"::"VAT Reg. No. Without EU Country Code":
                begin
                    CountryRegion.Get(CountryCode);
                    if CountryRegion."EU Country/Region Code" <> '' then
                        CountryCode := CountryRegion."EU Country/Region Code";
                    if CopyStr(VATRegNo, 1, StrLen(DelChr(CountryCode, '<>'))) =
                       DelChr(CountryCode, '<>')
                    then
                        exit(CopyStr(VATRegNo, StrLen(DelChr(CountryCode, '<>')) + 1, 50));
                    exit(VATRegNo);
                end;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateDefaultAdvancedIntrastatSetup()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRoundTotalWeight(var IsHandled: Boolean; var TotalWeight: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckTemplateName(CurrentJnlTemplateName: Code[10]; var CurrentJnlBatchName: Code[10]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOpenJnl(var CurrentJnlBatchName: Code[10]; var IntrastatJnlLine: Record "Intrastat Jnl. Line")
    begin
    end;
}
#endif