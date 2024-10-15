report 12483 "Posted Purchase Receipt M-4"
{
    Caption = 'Posted Purchase Receipt M-4';
    ProcessingOnly = true;

    dataset
    {
        dataitem("Purch. Inv. Header"; "Purch. Inv. Header")
        {
            dataitem("Invoice Post. Buffer"; "Invoice Post. Buffer")
            {
                DataItemTableView = SORTING(Type, "G/L Account", "Gen. Bus. Posting Group", "Gen. Prod. Posting Group", "VAT Bus. Posting Group", "VAT Prod. Posting Group", "Tax Area Code", "Tax Group Code", "Tax Liable", "Use Tax", "Dimension Set ID", "Job No.", "Fixed Asset Line No.");

                trigger OnAfterGetRecord()
                begin
                    if "G/L Account" <> AccNo then
                        InventoryReportsHelper.FillM4BodyInv("G/L Account");
                end;
            }
            dataitem("Purch. Inv. Line"; "Purch. Inv. Line")
            {
                DataItemLink = "Document No." = FIELD("No.");
                DataItemTableView = SORTING("Document No.", "Line No.");

                trigger OnAfterGetRecord()
                begin
                    if "Purch. Inv. Header"."Currency Code" <> '' then begin
                        Amount := Round(Amount / CurrencyFactor, Currency."Amount Rounding Precision");
                        "Amount Including VAT" := Round("Amount Including VAT" / CurrencyFactor, Currency."Amount Rounding Precision");
                    end;

                    if (Type <> Type::" ") and (Quantity <> 0) then
                        UnitCost := Round(Amount / Quantity, 0.00001);
                    TotalAmount += "Amount (LCY)";
                    TotalAmountInclVAT += "Amount Including VAT (LCY)";

                    if StdRepMgt.VATExemptLine("VAT Bus. Posting Group", "VAT Prod. Posting Group") then
                        StdRepMgt.FormatVATExemptLine(LineVATText[1], LineVATText[2])
                    else begin
                        VATExemptTotal := false;
                        LineVATText[2] :=
                          StdRepMgt.FormatReportValue("Amount Including VAT (LCY)" - "Amount (LCY)", 2);
                    end;

                    if Type <> Type::" " then
                        TotalQtyToReceive := TotalQtyToReceive + Quantity;

                    FillBody;
                end;

                trigger OnPostDataItem()
                begin
                    FormatTotalAmounts;

                    FillReportFooter;
                end;

                trigger OnPreDataItem()
                begin
                    VATExemptTotal := true;

                    InventoryReportsHelper.FillM4PageHeader;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                InvPostBuffer.DeleteAll;
                AccNo := '';
                CompanyInfo.Get;

                PurchInvLine.Reset;
                PurchInvLine.SetRange("Document No.", "Purch. Inv. Header"."No.");
                if PurchInvLine.FindSet then
                    repeat
                        case PurchInvLine.Type of
                            PurchInvLine.Type::"G/L Account":
                                InventoryReportsHelper.InsertBuffer(InvPostBuffer, PurchInvLine."No.", AccNo);
                            PurchInvLine.Type::Item:
                                begin
                                    InvPostingSetup.Get("Location Code", PurchInvLine."Posting Group");
                                    InventoryReportsHelper.InsertBuffer(InvPostBuffer, InvPostingSetup."Inventory Account (Interim)", AccNo);
                                end;
                            PurchInvLine.Type::"Charge (Item)":
                                begin
                                    GeneralPostingSetup.Get("Gen. Bus. Posting Group", PurchInvLine."Gen. Prod. Posting Group");
                                    InventoryReportsHelper.InsertBuffer(InvPostBuffer, GeneralPostingSetup."Purch. Account", AccNo);
                                end;
                            PurchInvLine.Type::"Fixed Asset":
                                begin
                                    PurchInvLine.TestField("Depreciation Book Code");
                                    FADepreciationBook.Get(PurchInvLine."No.", PurchInvLine."Depreciation Book Code");
                                    FAPostingGroup.Get(FADepreciationBook."FA Posting Group");
                                    InventoryReportsHelper.InsertBuffer(InvPostBuffer, FAPostingGroup."Acquisition Cost Account", AccNo);
                                end;
                            PurchInvLine.Type::"Empl. Purchase":
                                begin
                                    VendPostingGroup.Get("Vendor Posting Group");
                                    InventoryReportsHelper.InsertBuffer(InvPostBuffer, VendPostingGroup."Payables Account", AccNo);
                                end;
                        end;
                    until PurchInvLine.Next = 0;

                if "Currency Code" <> '' then
                    Currency.Get("Currency Code")
                else
                    Currency.InitRoundingPrecision;

                CurrencyFactor := "Currency Factor";
                if CurrencyFactor = 0 then
                    CurrencyFactor := 1;

                CheckSignature(ReleasedBy, ReleasedBy."Employee Type"::ReleasedBy);
                CheckSignature(ReceivedBy, ReceivedBy."Employee Type"::ReceivedBy);

                FillReportTitle;
            end;
        }
    }

    requestpage
    {

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnPostReport()
    begin
        if FileName <> '' then
            InventoryReportsHelper.ExportDataFile(FileName)
        else
            InventoryReportsHelper.ExportData;
    end;

    trigger OnPreReport()
    begin
        InitReportTemplate;
    end;

    var
        CompanyInfo: Record "Company Information";
        GeneralPostingSetup: Record "General Posting Setup";
        InvPostingSetup: Record "Inventory Posting Setup";
        PurchInvLine: Record "Purch. Inv. Line";
        InvPostBuffer: Record "Invoice Post. Buffer";
        FADepreciationBook: Record "FA Depreciation Book";
        FAPostingGroup: Record "FA Posting Group";
        VendPostingGroup: Record "Vendor Posting Group";
        ReleasedBy: Record "Posted Document Signature";
        ReceivedBy: Record "Posted Document Signature";
        Currency: Record Currency;
        StdRepMgt: Codeunit "Local Report Management";
        DocSignMgt: Codeunit "Doc. Signature Management";
        InventoryReportsHelper: Codeunit "Purchase Receipt M-4 Helper";
        AccNo: Code[20];
        CurrencyFactor: Decimal;
        TotalAmount: Decimal;
        TotalAmountInclVAT: Decimal;
        UnitCost: Decimal;
        LineVATText: array[2] of Text[50];
        TotalVATAmountText: Text[50];
        FileName: Text;
        VATExemptTotal: Boolean;
        TotalQtyToReceive: Decimal;

    [Scope('OnPrem')]
    procedure CheckSignature(var PostedDocSign: Record "Posted Document Signature"; EmpType: Integer)
    begin
        DocSignMgt.GetPostedDocSign(
          PostedDocSign, DATABASE::"Purch. Inv. Header",
          0, "Purch. Inv. Header"."No.", EmpType, false);
    end;

    [Scope('OnPrem')]
    procedure FormatTotalAmounts()
    begin
        if VATExemptTotal then
            TotalVATAmountText := '-'
        else
            TotalVATAmountText := StdRepMgt.FormatReportValue(TotalAmountInclVAT - TotalAmount, 2);
    end;

    [Scope('OnPrem')]
    procedure InitReportTemplate()
    begin
        InventoryReportsHelper.InitM4Report;
    end;

    [Scope('OnPrem')]
    procedure SetFileNameSilent(NewFileName: Text)
    begin
        FileName := NewFileName;
    end;

    local procedure FillReportTitle()
    var
        ReportHeaderArr: array[10] of Text;
    begin
        with "Purch. Inv. Header" do begin
            ReportHeaderArr[1] := StdRepMgt.GetCompanyName;
            ReportHeaderArr[2] := ReceivedBy."Employee Org. Unit";
            ReportHeaderArr[3] := CompanyInfo."OKPO Code";
            ReportHeaderArr[4] := "No.";
            ReportHeaderArr[5] := Format("Document Date");
            ReportHeaderArr[6] := "Location Code";
            ReportHeaderArr[7] := StdRepMgt.GetVendorName("Buy-from Vendor No.");
            ReportHeaderArr[8] := "Buy-from Vendor No.";
            ReportHeaderArr[9] := AccNo;
            ReportHeaderArr[10] := "Vendor Invoice No.";
        end;

        InventoryReportsHelper.FillM4ReportTitle(ReportHeaderArr);
    end;

    [Scope('OnPrem')]
    procedure FillBody()
    var
        PageHeaderArr: array[10] of Text;
    begin
        with "Purch. Inv. Line" do begin
            PageHeaderArr[1] := Description + "Description 2";
            PageHeaderArr[2] := "No.";
            PageHeaderArr[3] := "Unit of Measure Code";
            PageHeaderArr[4] := "Unit of Measure";
            PageHeaderArr[5] := Format(Quantity);
            PageHeaderArr[6] := Format(Quantity);
            PageHeaderArr[7] := FormatAmount(UnitCost);
            PageHeaderArr[8] := FormatAmount(Amount);
            PageHeaderArr[9] := LineVATText[2];
            PageHeaderArr[10] := FormatAmount("Amount Including VAT");
        end;

        InventoryReportsHelper.FillM4Body(PageHeaderArr);
    end;

    local procedure FillReportFooter()
    var
        ReportFooterArr: array[8] of Text;
    begin
        ReportFooterArr[1] := Format(TotalQtyToReceive);
        ReportFooterArr[2] := FormatAmount(TotalAmount);
        ReportFooterArr[3] := TotalVATAmountText;
        ReportFooterArr[4] := FormatAmount(TotalAmountInclVAT);
        ReportFooterArr[5] := ReceivedBy."Employee Job Title";
        ReportFooterArr[6] := ReceivedBy."Employee Name";
        ReportFooterArr[7] := ReleasedBy."Employee Job Title";
        ReportFooterArr[8] := ReleasedBy."Employee Name";

        InventoryReportsHelper.FillM4ReportFooter(ReportFooterArr);
    end;

    local procedure FormatAmount(Amount: Decimal): Text
    begin
        exit(StdRepMgt.FormatReportValue(Amount, 2));
    end;
}

