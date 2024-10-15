codeunit 7000010 "Company-Initialize Cartera"
{

    trigger OnRun()
    begin
        with CarteraSetup do
            if not FindFirst then begin
                Init;
                Insert;
            end;

        InsertSourceCode(SourceCodeSetup."Cartera Journal", Text1100000, Text1100001);

        with CarteraReportSelection do
            if not FindFirst then begin
                InsertBGPORepSelection(Usage::"Bill Group", '1', REPORT::"Bill Group Listing");
                InsertBGPORepSelection(Usage::"Posted Bill Group", '1', REPORT::"Posted Bill Group Listing");
                InsertBGPORepSelection(Usage::"Closed Bill Group", '1', REPORT::"Closed Bill Group Listing");
                InsertBGPORepSelection(Usage::Bill, '1', REPORT::"Receivable Bill");
                InsertBGPORepSelection(Usage::"Bill Group - Test", '1', REPORT::"Bill Group - Test");
                InsertBGPORepSelection(Usage::"Posted Payment Order", '1', REPORT::"Posted Payment Order Listing");
                InsertBGPORepSelection(Usage::"Closed Payment Order", '1', REPORT::"Closed Payment Order Listing");
                InsertBGPORepSelection(Usage::"Payment Order", '1', REPORT::"Payment Order Listing");
                InsertBGPORepSelection(Usage::"Payment Order - Test", '1', REPORT::"Payment Order - Test");
            end;
    end;

    var
        Text1100000: Label 'CARJNL';
        CarteraSetup: Record "Cartera Setup";
        SourceCode: Record "Source Code";
        SourceCodeSetup: Record "Source Code Setup";
        CarteraReportSelection: Record "Cartera Report Selections";
        Text1100001: Label 'Cartera Journal';

    local procedure InsertSourceCode(var SourceCodeDefCode: Code[10]; "Code": Code[10]; Description: Text[50])
    begin
        SourceCodeDefCode := Code;
        SourceCode.Init();
        SourceCode.Code := Code;
        SourceCode.Description := Description;
        if SourceCode.Insert() then;
    end;

    local procedure InsertBGPORepSelection(ReportUsage: Integer; Sequence: Code[10]; ReportID: Integer)
    begin
        CarteraReportSelection.Init();
        CarteraReportSelection.Usage := ReportUsage;
        CarteraReportSelection.Sequence := Sequence;
        CarteraReportSelection."Report ID" := ReportID;
        CarteraReportSelection.Insert();
    end;
}

