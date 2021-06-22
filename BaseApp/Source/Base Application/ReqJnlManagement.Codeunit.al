codeunit 330 ReqJnlManagement
{
    Permissions = TableData "Req. Wksh. Template" = imd,
                  TableData "Requisition Wksh. Name" = imd;

    trigger OnRun()
    begin
    end;

    var
        Text002: Label 'RECURRING';
        Text004: Label 'DEFAULT';
        Text005: Label 'Default Journal';
        Text99000000: Label '%1 Worksheet';
        Text99000001: Label 'Recurring Worksheet';
        LastReqLine: Record "Requisition Line";
        OpenFromBatch: Boolean;

    procedure TemplateSelection(PageID: Integer; RecurringJnl: Boolean; Type: Option "Req.","For. Labor",Planning; var ReqLine: Record "Requisition Line"; var JnlSelected: Boolean)
    var
        ReqWkshTmpl: Record "Req. Wksh. Template";
        LocalText000: Label 'Req.,For. Labor,Planning';
    begin
        JnlSelected := true;

        ReqWkshTmpl.Reset();
        ReqWkshTmpl.SetRange("Page ID", PageID);
        ReqWkshTmpl.SetRange(Recurring, RecurringJnl);
        ReqWkshTmpl.SetRange(Type, Type);
        OnTemplateSelectionSetFilter(ReqWkshTmpl, Type);

        case ReqWkshTmpl.Count of
            0:
                begin
                    ReqWkshTmpl.Init();
                    ReqWkshTmpl.Recurring := RecurringJnl;
                    ReqWkshTmpl.Type := Type;
                    if not RecurringJnl then begin
                        ReqWkshTmpl.Name := CopyStr(Format(SelectStr(Type + 1, LocalText000)), 1, MaxStrLen(ReqWkshTmpl.Name));
                        ReqWkshTmpl.Description := StrSubstNo(Text99000000, SelectStr(Type + 1, LocalText000));
                    end else begin
                        ReqWkshTmpl.Name := Text002;
                        ReqWkshTmpl.Description := Text99000001;
                    end;
                    ReqWkshTmpl.Validate("Page ID");
                    ReqWkshTmpl.Insert();
                    Commit();
                end;
            1:
                ReqWkshTmpl.FindFirst;
            else
                JnlSelected := PAGE.RunModal(0, ReqWkshTmpl) = ACTION::LookupOK;
        end;
        if JnlSelected then begin
            ReqLine.FilterGroup := 2;
            ReqLine.SetRange("Worksheet Template Name", ReqWkshTmpl.Name);
            ReqLine.FilterGroup := 0;
            if OpenFromBatch then begin
                ReqLine."Worksheet Template Name" := '';
                PAGE.Run(ReqWkshTmpl."Page ID", ReqLine);
            end;
        end;
    end;

    procedure TemplateSelectionFromBatch(var ReqWkshName: Record "Requisition Wksh. Name")
    var
        ReqLine: Record "Requisition Line";
        ReqWkshTmpl: Record "Req. Wksh. Template";
    begin
        OpenFromBatch := true;
        ReqWkshTmpl.Get(ReqWkshName."Worksheet Template Name");
        ReqWkshTmpl.TestField("Page ID");
        ReqWkshName.TestField(Name);

        ReqLine.FilterGroup := 2;
        ReqLine.SetRange("Worksheet Template Name", ReqWkshTmpl.Name);
        ReqLine.FilterGroup := 0;

        ReqLine."Worksheet Template Name" := '';
        ReqLine."Journal Batch Name" := ReqWkshName.Name;
        PAGE.Run(ReqWkshTmpl."Page ID", ReqLine);
    end;

    procedure OpenJnl(var CurrentJnlBatchName: Code[10]; var ReqLine: Record "Requisition Line")
    begin
        OnBeforeOpenJnl(CurrentJnlBatchName, ReqLine);

        CheckTemplateName(ReqLine.GetRangeMax("Worksheet Template Name"), CurrentJnlBatchName);
        ReqLine.FilterGroup := 2;
        ReqLine.SetRange("Journal Batch Name", CurrentJnlBatchName);
        ReqLine.FilterGroup := 0;
    end;

    procedure OpenJnlBatch(var ReqWkshName: Record "Requisition Wksh. Name")
    var
        ReqWkshTmpl: Record "Req. Wksh. Template";
        ReqLine: Record "Requisition Line";
        JnlSelected: Boolean;
    begin
        if ReqWkshName.GetFilter("Worksheet Template Name") <> '' then
            exit;
        ReqWkshName.FilterGroup(2);
        if ReqWkshName.GetFilter("Worksheet Template Name") <> '' then begin
            ReqWkshName.FilterGroup(0);
            exit;
        end;
        ReqWkshName.FilterGroup(0);

        if not ReqWkshName.Find('-') then
            for ReqWkshTmpl.Type := ReqWkshTmpl.Type::"Req." to ReqWkshTmpl.Type::Planning do begin
                ReqWkshTmpl.SetRange(Type, ReqWkshTmpl.Type);
                if not ReqWkshTmpl.FindFirst then
                    TemplateSelection(0, false, ReqWkshTmpl.Type, ReqLine, JnlSelected);
                if ReqWkshTmpl.FindFirst then
                    CheckTemplateName(ReqWkshTmpl.Name, ReqWkshName.Name);
                if ReqWkshTmpl.Type in [ReqWkshTmpl.Type::"Req."] then begin
                    ReqWkshTmpl.SetRange(Recurring, true);
                    if not ReqWkshTmpl.FindFirst then
                        TemplateSelection(0, true, ReqWkshTmpl.Type, ReqLine, JnlSelected);
                    if ReqWkshTmpl.FindFirst then
                        CheckTemplateName(ReqWkshTmpl.Name, ReqWkshName.Name);
                    ReqWkshTmpl.SetRange(Recurring);
                end;
            end;

        ReqWkshName.Find('-');
        JnlSelected := true;
        ReqWkshName.CalcFields("Template Type", Recurring);
        ReqWkshTmpl.SetRange(Recurring, ReqWkshName.Recurring);
        if not ReqWkshName.Recurring then
            ReqWkshTmpl.SetRange(Type, ReqWkshName."Template Type");
        if ReqWkshName.GetFilter("Worksheet Template Name") <> '' then
            ReqWkshTmpl.SetRange(Name, ReqWkshName.GetFilter("Worksheet Template Name"));
        case ReqWkshTmpl.Count of
            1:
                ReqWkshTmpl.FindFirst;
            else
                JnlSelected := PAGE.RunModal(0, ReqWkshTmpl) = ACTION::LookupOK;
        end;
        if not JnlSelected then
            Error('');

        ReqWkshName.FilterGroup(0);
        ReqWkshName.SetRange("Worksheet Template Name", ReqWkshTmpl.Name);
        ReqWkshName.FilterGroup(2);
    end;

    local procedure CheckTemplateName(CurrentJnlTemplateName: Code[10]; var CurrentJnlBatchName: Code[10])
    var
        ReqWkshName: Record "Requisition Wksh. Name";
    begin
        ReqWkshName.SetRange("Worksheet Template Name", CurrentJnlTemplateName);
        if not ReqWkshName.Get(CurrentJnlTemplateName, CurrentJnlBatchName) then begin
            if not ReqWkshName.FindFirst then begin
                ReqWkshName.Init();
                ReqWkshName."Worksheet Template Name" := CurrentJnlTemplateName;
                ReqWkshName.Name := Text004;
                ReqWkshName.Description := Text005;
                ReqWkshName.Insert(true);
                Commit();
            end;
            CurrentJnlBatchName := ReqWkshName.Name
        end;
    end;

    procedure CheckName(CurrentJnlBatchName: Code[10]; var ReqLine: Record "Requisition Line")
    var
        ReqWkshName: Record "Requisition Wksh. Name";
    begin
        ReqWkshName.Get(ReqLine.GetRangeMax("Worksheet Template Name"), CurrentJnlBatchName);
    end;

    procedure SetName(CurrentJnlBatchName: Code[10]; var ReqLine: Record "Requisition Line")
    begin
        ReqLine.FilterGroup := 2;
        ReqLine.SetRange("Journal Batch Name", CurrentJnlBatchName);
        ReqLine.FilterGroup := 0;
        if ReqLine.Find('-') then;
    end;

    procedure LookupName(var CurrentJnlBatchName: Code[10]; var ReqLine: Record "Requisition Line")
    var
        ReqWkshName: Record "Requisition Wksh. Name";
    begin
        Commit();
        ReqWkshName."Worksheet Template Name" := ReqLine.GetRangeMax("Worksheet Template Name");
        ReqWkshName.Name := ReqLine.GetRangeMax("Journal Batch Name");
        ReqWkshName.FilterGroup(2);
        ReqWkshName.SetRange("Worksheet Template Name", ReqWkshName."Worksheet Template Name");
        ReqWkshName.FilterGroup(0);
        OnBeforeLookupName(ReqWkshName);
        if PAGE.RunModal(0, ReqWkshName) = ACTION::LookupOK then begin
            CurrentJnlBatchName := ReqWkshName.Name;
            SetName(CurrentJnlBatchName, ReqLine);
        end;
    end;

    procedure GetDescriptionAndRcptName(var ReqLine: Record "Requisition Line"; var Description: Text[100]; var BuyFromVendorName: Text[100])
    var
        Vend: Record Vendor;
        GLAcc: Record "G/L Account";
    begin
        if ReqLine."No." = '' then
            Description := ''
        else
            if (ReqLine.Type <> LastReqLine.Type) or
               (ReqLine."No." <> LastReqLine."No.")
            then
                case ReqLine.Type of
                    ReqLine.Type::"G/L Account":
                        if GLAcc.Get(ReqLine."No.") then
                            Description := GLAcc.Name
                        else
                            Description := '';
                end;

        if ReqLine."Vendor No." = '' then
            BuyFromVendorName := ''
        else
            if ReqLine."Vendor No." <> LastReqLine."Vendor No." then begin
                if Vend.Get(ReqLine."Vendor No.") then
                    BuyFromVendorName := Vend.Name
                else
                    BuyFromVendorName := '';
            end;

        LastReqLine := ReqLine;
    end;

    procedure SetUpNewLine(var ReqLine: Record "Requisition Line"; LastReqLine: Record "Requisition Line")
    begin
        ReqLine.Type := LastReqLine.Type;
        ReqLine."Recurring Method" := LastReqLine."Recurring Method";
        ReqLine."Order Date" := LastReqLine."Order Date";

        OnAfterSetUpNewLine(ReqLine, LastReqLine);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetUpNewLine(var ReqLine: Record "Requisition Line"; var LastReqLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupName(var ReqWkshName: Record "Requisition Wksh. Name")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOpenJnl(var CurrentJnlBatchName: Code[10]; var ReqLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTemplateSelectionSetFilter(var ReqWkshTemplate: Record "Req. Wksh. Template"; var Type: Option)
    begin
    end;
}

