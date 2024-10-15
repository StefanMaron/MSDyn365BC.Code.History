codeunit 143021 "Library - VAT Ctrl. Rpt. Stat."
{

    trigger OnRun()
    begin
    end;

    var
        TempVATControlReportBuffer: Record "VAT Control Report Buffer" temporary;
        VATControlReportHeader: Record "VAT Control Report Header";

    local procedure CreateBuffer(SectionCode: Code[20]; Base1: Decimal; Base2: Decimal; Base3: Decimal; Amount1: Decimal; Amount2: Decimal; Amount3: Decimal; TotalBase: Decimal; TotalAmount: Decimal)
    begin
        with TempVATControlReportBuffer do begin
            Init;
            "VAT Control Rep. Section Code" := SectionCode;
            "Base 1" := Base1;
            "Base 2" := Base2;
            "Base 3" := Base3;
            "Amount 1" := Amount1;
            "Amount 2" := Amount2;
            "Amount 3" := Amount3;
            "Total Base" := TotalBase;
            "Total Amount" := TotalAmount;
            Insert;
        end;
    end;

    [Scope('OnPrem')]
    procedure GetLineWithSection(SectionCode: Code[20]; var TempVATControlReportBuffer2: Record "VAT Control Report Buffer" temporary)
    begin
        if TempVATControlReportBuffer.IsEmpty() then
            exit;

        TempVATControlReportBuffer.Get(SectionCode);
        TempVATControlReportBuffer2 := TempVATControlReportBuffer;
    end;

    local procedure Initialize()
    begin
        ClearAll;
    end;

    local procedure OpenVATControlReportStatistics()
    var
        VATControlReportCard: TestPage "VAT Control Report Card";
    begin
        if VATControlReportHeader."No." = '' then
            exit;

        VATControlReportCard.OpenView;
        VATControlReportCard.GotoKey(VATControlReportHeader."No.");
        VATControlReportCard.Statistics.Invoke;
        VATControlReportCard.OK.Invoke;
    end;

    [Scope('OnPrem')]
    procedure SetVATControlReportHeader(var NewVATControlReportHeader: Record "VAT Control Report Header")
    begin
        Initialize;
        VATControlReportHeader := NewVATControlReportHeader;
        OpenVATControlReportStatistics;
    end;

    [Scope('OnPrem')]
    procedure SetVATControlReportStatistics(var VATControlReportStatistics: TestPage "VAT Control Report Statistics")
    begin
        if VATControlReportStatistics.SubForm.First then
            repeat
                CreateBuffer(
                  VATControlReportStatistics.SubForm."VAT Control Rep. Section Code".Value,
                  TextToDecimal(VATControlReportStatistics.SubForm."Base 1".Value),
                  TextToDecimal(VATControlReportStatistics.SubForm."Base 2".Value),
                  TextToDecimal(VATControlReportStatistics.SubForm."<Base 3>".Value),
                  TextToDecimal(VATControlReportStatistics.SubForm."Amount 1".Value),
                  TextToDecimal(VATControlReportStatistics.SubForm."Amount 2".Value),
                  TextToDecimal(VATControlReportStatistics.SubForm."Amount 3".Value),
                  TextToDecimal(VATControlReportStatistics.SubForm."Total Base".Value),
                  TextToDecimal(VATControlReportStatistics.SubForm."Total Amount".Value));
            until not VATControlReportStatistics.SubForm.Next;
    end;

    local procedure TextToDecimal(TextValue: Text): Decimal
    var
        DecValue: Decimal;
    begin
        if Evaluate(DecValue, TextValue) then
            exit(DecValue);
        exit(0);
    end;
}

