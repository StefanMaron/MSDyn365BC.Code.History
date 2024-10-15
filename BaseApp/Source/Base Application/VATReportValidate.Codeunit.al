codeunit 744 "VAT Report Validate"
{
    TableNo = "VAT Report Header";

    trigger OnRun()
    begin
        ClearErrorLog;

        ValidateVATReportLinesExists(Rec);
        ValidateVATReportHeader(Rec);
        ValidateVATReportLines(Rec);

        ShowErrorLog;
    end;

    var
        Text000: Label 'You cannot release the VAT report because no lines exist.';
        TempVATReportErrorLog: Record "VAT Report Error Log" temporary;
        VATReportLine: Record "VAT Report Line";
        ErrorID: Integer;
        Text001: Label 'Field %1 should be filled in table %2.';
        Text002: Label 'Period from %1 till %2 already exists on VAT Report %3.';
        Text003: Label 'Each cancellation line should have related corrective line.';
        Text004: Label 'The %1 cannot be earlier than the %1 %2 (VAT Report %3).';

    local procedure ClearErrorLog()
    begin
        TempVATReportErrorLog.Reset();
        TempVATReportErrorLog.DeleteAll();
    end;

    local procedure InsertErrorLog(ErrorMessage: Text[250])
    begin
        if TempVATReportErrorLog.FindLast then
            ErrorID := TempVATReportErrorLog."Entry No." + 1
        else
            ErrorID := 1;

        TempVATReportErrorLog.Init();
        TempVATReportErrorLog."Entry No." := ErrorID;
        TempVATReportErrorLog."Error Message" := ErrorMessage;
        TempVATReportErrorLog.Insert();
    end;

    local procedure ShowErrorLog()
    begin
        if not TempVATReportErrorLog.IsEmpty() then begin
            PAGE.Run(PAGE::"VAT Report Error Log", TempVATReportErrorLog);
            Error('');
        end;
    end;

    local procedure ValidateVATReportLinesExists(VATReportHeader: Record "VAT Report Header")
    begin
        VATReportLine.SetRange("VAT Report No.", VATReportHeader."No.");
        if VATReportLine.IsEmpty() then begin
            InsertErrorLog(Text000);
            ShowErrorLog;
        end;
    end;

    local procedure ValidateVATReportHeader(VATReportHeader: Record "VAT Report Header")
    var
        OrigVATReport: Record "VAT Report Header";
    begin
        with VATReportHeader do begin
            if "No." = '' then
                InsertErrorLog(StrSubstNo(Text001, FieldCaption("No."), TableCaption));
            if "Start Date" = 0D then
                InsertErrorLog(StrSubstNo(Text001, FieldCaption("Start Date"), TableCaption));
            if "End Date" = 0D then
                InsertErrorLog(StrSubstNo(Text001, FieldCaption("End Date"), TableCaption));
            if "Processing Date" = 0D then
                InsertErrorLog(StrSubstNo(Text001, FieldCaption("Processing Date"), TableCaption));
            if "Report Period Type" = "Report Period Type"::" " then
                InsertErrorLog(StrSubstNo(Text001, FieldCaption("Report Period Type"), TableCaption));
            if "Report Period No." = 0 then
                InsertErrorLog(StrSubstNo(Text001, FieldCaption("Report Period No."), TableCaption));
            if "Report Year" = 0 then
                InsertErrorLog(StrSubstNo(Text001, FieldCaption("Report Year"), TableCaption));
            if "Company Name" = '' then
                InsertErrorLog(StrSubstNo(Text001, FieldCaption("Company Name"), TableCaption));
            if "Company Address" = '' then
                InsertErrorLog(StrSubstNo(Text001, FieldCaption("Company Address"), TableCaption));
            if "Post Code" = '' then
                InsertErrorLog(StrSubstNo(Text001, FieldCaption("Post Code"), TableCaption));
            if City = '' then
                InsertErrorLog(StrSubstNo(Text001, FieldCaption(City), TableCaption));
            if "VAT Registration No." = '' then
                InsertErrorLog(StrSubstNo(Text001, FieldCaption("VAT Registration No."), TableCaption));
            case "VAT Report Type" of
                "VAT Report Type"::Standard:
                    begin
                        TestField("Original Report No.", '');
                        ValidateVATReportPeriod(VATReportHeader);
                    end;
                "VAT Report Type"::Corrective:
                    begin
                        TestField("Original Report No.");
                        OrigVATReport.Get("Original Report No.");
                        TestField("Start Date", OrigVATReport."Start Date");
                        TestField("End Date", OrigVATReport."End Date");
                        TestField("Report Period Type", OrigVATReport."Report Period Type");
                        TestField("Report Period No.", OrigVATReport."Report Period No.");
                        TestField("Report Year", OrigVATReport."Report Year");
                        if OrigVATReport."Processing Date" > "Processing Date" then
                            Error(Text004,
                              FieldCaption("Processing Date"), OrigVATReport."Processing Date", OrigVATReport."No.");
                    end;
            end;
        end;
    end;

    local procedure ValidateVATReportLines(VATReportHeader: Record "VAT Report Header")
    var
        VATReportLine: Record "VAT Report Line";
        CancelLines: Integer;
        CorrectLines: Integer;
    begin
        with VATReportLine do begin
            SetRange("VAT Report No.", VATReportHeader."No.");
            if FindSet then
                repeat
                    if "Country/Region Code" = '' then
                        InsertErrorLog(StrSubstNo(Text001, FieldCaption("Country/Region Code"), TableCaption));
                    if "VAT Registration No." = '' then
                        InsertErrorLog(StrSubstNo(Text001, FieldCaption("VAT Registration No."), TableCaption));
                    case "Line Type" of
                        "Line Type"::Cancellation:
                            CancelLines += 1;
                        "Line Type"::Correction:
                            CorrectLines += 1;
                    end;
                until Next() = 0;
            if CancelLines <> CorrectLines then
                Error(Text003);
        end;
    end;

    [Scope('OnPrem')]
    procedure ValidateVATReportPeriod(VATReportHeader: Record "VAT Report Header")
    var
        VATReportHeader2: Record "VAT Report Header";
    begin
        if VATReportHeader."Original Report No." = '' then begin
            VATReportHeader2.Reset();
            VATReportHeader2.SetRange("Start Date", VATReportHeader."Start Date");
            VATReportHeader2.SetRange("End Date", VATReportHeader."End Date");
            VATReportHeader2.SetRange("Original Report No.", '');
            VATReportHeader2.SetRange("VAT Report Type", VATReportHeader."VAT Report Type");
            VATReportHeader2.SetRange("Trade Type", VATReportHeader."Trade Type");
            VATReportHeader2.SetFilter("No.", '<>%1', VATReportHeader."No.");
            if VATReportHeader2.FindFirst then
                Error(Text002,
                  VATReportHeader."Start Date", VATReportHeader."End Date", VATReportHeader2."No.");
        end;
    end;
}

