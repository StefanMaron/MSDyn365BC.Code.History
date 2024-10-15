codeunit 10686 "Elec. VAT Validate Return"
{
    TableNo = "VAT Report Header";

    var
        IncorrectSignErr: Label 'The amount in the box %1 has an incorrect sign. It must be %2.', Comment = '%1 = number, %2 = either positive or negative';
        PositiveLbl: Label 'positive';
        NegativeLbl: Label 'negative';
        VATAmountCalcErr: Label 'The VAT amount in the box %1 is not equal to the base VAT * VAT Rate.', Comment = '%1 - number';

    trigger OnRun()
    begin
        codeunit.Run(Codeunit::"VAT Report Validate", Rec);
        ValidateVATReport(Rec);
    end;

    local procedure ValidateVATReport(VATReportHeader: Record "VAT Report Header")
    var
        VATStatementReportLine: Record "VAT Statement Report Line";
        ErrorMessage: Record "Error Message";
        CompanyInformation: Record "Company Information";
        VATCode: Record "VAT Code";
        VATCodeValue: Code[10];
        ExpectedVATAmount: Decimal;
    begin
        ErrorMessage.SetContext(VATReportHeader);
        CompanyInformation.Get();
        ErrorMessage.ClearLogRec(CompanyInformation);
        ErrorMessage.LogIfEmpty(CompanyInformation, CompanyInformation.FieldNo("VAT Registration No."), ErrorMessage."Message Type"::Error);

        VATStatementReportLine.SetRange("VAT Report Config. Code", VATReportHeader."VAT Report Config. Code");
        VATStatementReportLine.SetRange("VAT Report No.", VATReportHeader."No.");
        VATStatementReportLine.FindSet();
        repeat
            If VATStatementReportLine."Box No." in ['1', '11', '12', '13', '14', '15'] then begin
                if VATStatementReportLine.Amount > 0 then
                    Error(IncorrectSignErr, VATStatementReportLine."Box No.", NegativeLbl);
            end else
                if VATStatementReportLine.Amount < 0 then
                    Error(IncorrectSignErr, VATStatementReportLine."Box No.", PositiveLbl);
            VATCodeValue := CopyStr(VATStatementReportLine."Box No.", 1, MaxStrLen(VATCodeValue));
            VATCode.Get(VATCodeValue);
            if VATCode."Report VAT Rate" and (VATStatementReportLine.Base <> 0) then begin
                ExpectedVATAmount := Round(VATStatementReportLine.Base * VATCode."VAT Rate For Reporting" / 100);
                if abs(ExpectedVATAmount - VATStatementReportLine.Amount) > 1 then
                    error(VATAmountCalcErr, VATStatementReportLine."Box No.");
            end;

        until VATStatementReportLine.Next() = 0;
    end;
}
