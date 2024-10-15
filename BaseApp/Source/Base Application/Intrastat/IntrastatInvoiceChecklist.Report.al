#if not CLEAN18
report 31061 "Intrastat - Invoice Checklist"
{
    Caption = 'Intrastat - Invoice Checklist (Obsolete)';
    DefaultLayout = RDLC;
    RDLCLayout = './Intrastat/IntrastatInvoiceChecklist.rdlc';
    ObsoleteState = Pending;
    ObsoleteReason = 'Moved to Core Localization Pack for Czech.';
    ObsoleteTag = '18.0';

    dataset
    {
        dataitem("Intrastat Jnl. Line"; "Intrastat Jnl. Line")
        {
            DataItemTableView = SORTING("Journal Template Name", "Journal Batch Name", "Line No.");
            RequestFilterFields = "Journal Template Name", "Journal Batch Name", Type;
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName)
            {
            }
            column(USERID; UserId)
            {
            }
            column(Intrastat_Jnl__Line_Type; Type)
            {
            }
            column(Intrastat_Jnl__Line__Item_Description_; "Item Description")
            {
            }
            column(Intrastat_Jnl__Line__Tariff_No__; "Tariff No.")
            {
            }
            column(Intrastat_Jnl__Line__Transaction_Type_; "Transaction Type")
            {
            }
            column(Intrastat_Jnl__Line__Shipment_Method_Code_; "Shpt. Method Code")
            {
            }
            column(Intrastat_Jnl__Line__Transport_Method_; "Transport Method")
            {
            }
            column(Intrastat_Jnl__Line_Quantity; Quantity)
            {
            }
            column(Intrastat_Jnl__Line__Total_Weight_; "Total Weight")
            {
            }
            column(Intrastat_Jnl__Line_Amount; Amount)
            {
            }
            column(Intrastat_Jnl__Line__Item_No__; "Item No.")
            {
            }
            column(Intrastat_Jnl__Line_Area; Area)
            {
            }
            column(Intrastat_Jnl__Line__Transaction_Specification_; "Transaction Specification")
            {
            }
            column(Intrastat_Jnl__Line__Country_Region_Code_; "Country/Region Code")
            {
            }
            column(greItemEntry__Document_No__; greItemEntry."Document No.")
            {
            }
            column(gteDocType; gteDocType)
            {
            }
            column(greItemEntry__Posting_Date_; greItemEntry."Posting Date")
            {
            }
            column(Intrastat___Invoice_ChecklistCaption; Intrastat___Invoice_ChecklistCaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(Intrastat_Jnl__Line_AmountCaption; FieldCaption(Amount))
            {
            }
            column(Intrastat_Jnl__Line__Total_Weight_Caption; FieldCaption("Total Weight"))
            {
            }
            column(Intrastat_Jnl__Line_QuantityCaption; FieldCaption(Quantity))
            {
            }
            column(Intrastat_Jnl__Line__Shipment_Method_Code_Caption; FieldCaption("Shpt. Method Code"))
            {
            }
            column(Intrastat_Jnl__Line__Transport_Method_Caption; FieldCaption("Transport Method"))
            {
            }
            column(Intrastat_Jnl__Line__Transaction_Type_Caption; FieldCaption("Transaction Type"))
            {
            }
            column(Intrastat_Jnl__Line__Tariff_No__Caption; FieldCaption("Tariff No."))
            {
            }
            column(Intrastat_Jnl__Line__Item_Description_Caption; FieldCaption("Item Description"))
            {
            }
            column(greTBuffer__Document_No__Caption; greTBuffer__Document_No__CaptionLbl)
            {
            }
            column(greTBuffer_DescriptionCaption; greTBuffer_DescriptionCaptionLbl)
            {
            }
            column(Intrastat_Jnl__Line_TypeCaption; FieldCaption(Type))
            {
            }
            column(Intrastat_Jnl__Line__Item_No__Caption; FieldCaption("Item No."))
            {
            }
            column(greTBuffer__Posting_Date_Caption; greTBuffer__Posting_Date_CaptionLbl)
            {
            }
            column(Intrastat_Jnl__Line_AreaCaption; FieldCaption(Area))
            {
            }
            column(Intrastat_Jnl__Line__Transaction_Specification_Caption; FieldCaption("Transaction Specification"))
            {
            }
            column(Intrastat_Jnl__Line__Country_Region_Code_Caption; FieldCaption("Country/Region Code"))
            {
            }
            column(Intrastat_Jnl__Line_Journal_Template_Name; "Journal Template Name")
            {
            }
            column(Intrastat_Jnl__Line_Journal_Batch_Name; "Journal Batch Name")
            {
            }
            column(Intrastat_Jnl__Line_Line_No_; "Line No.")
            {
            }
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = SORTING(Number);
                column(greTBuffer_Description; greTBuffer.Description)
                {
                }
                column(greTBuffer__Document_No__; greTBuffer."Document No.")
                {
                }
                column(greTBuffer__Posting_Date_; greTBuffer."Posting Date")
                {
                }
                column(Integer_Number; Number)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if Number <> 1 then
                        greTBuffer.Next;

                    if greTBuffer."Debit Amount" + greTBuffer."Credit Amount" = 0 then
                        CurrReport.Skip();
                    if "Intrastat Jnl. Line".Type = "Intrastat Jnl. Line".Type::Shipment then begin
                        greTBuffer."Debit Amount" := -greTBuffer."Debit Amount";
                        greTBuffer."Credit Amount" := -greTBuffer."Credit Amount";
                    end;

                    if greTBuffer.Description = '' then begin
                        greTBuffer.Description := DocumentType(greTBuffer."Document No.");
                        greTBuffer.Modify();
                    end;
                end;

                trigger OnPreDataItem()
                begin
                    if not greTBuffer.FindSet() then
                        CurrReport.Break();

                    SetRange(Number, 1, greTBuffer.Count);
                end;
            }

            trigger OnAfterGetRecord()
            var
                lreValueEntry: Record "Value Entry";
                lreItemCharge: Record "Item Charge";
                ldeTotalAmt: Decimal;
                ldeTotalCostAmt: Decimal;
                ldeTotalAmtExpected: Decimal;
                ldeTotalCostAmtExpected: Decimal;
                linQuantityEntry: Integer;
                lboCalculate: Boolean;
            begin
                greTBuffer.DeleteAll();

                lreValueEntry.SetCurrentKey("Item Ledger Entry No.");
                lreValueEntry.SetRange("Item Ledger Entry No.", "Source Entry No.");
                lreValueEntry.SetRange("Posting Date", gdaStartDate, gdaEndDate);
                lreValueEntry.SetRange("Entry Type", lreValueEntry."Entry Type"::"Direct Cost");
                if lreValueEntry.FindSet() then
                    repeat
                        if lreValueEntry."Item Charge No." = '' then
                            lboCalculate := true
                        else
                            lreItemCharge.Get(lreValueEntry."Item Charge No.");
                        // aaa
                        /*
                        IF lreItemCharge."Intrastat Exclude" THEN
                          lboCalculate := FALSE
                        ELSE
                          lboCalculate := TRUE;
                      */
                        if lboCalculate then
                            if not greIntrastatJnlBatch."Amounts in Add. Currency" then begin
                                ldeTotalAmt := lreValueEntry."Sales Amount (Actual)";
                                ldeTotalCostAmt := lreValueEntry."Cost Amount (Actual)";
                                ldeTotalAmtExpected := ldeTotalAmtExpected + lreValueEntry."Sales Amount (Expected)";
                                ldeTotalCostAmtExpected := ldeTotalCostAmtExpected + lreValueEntry."Cost Amount (Expected)";
                            end else begin
                                ldeTotalCostAmt := lreValueEntry."Cost Amount (Actual) (ACY)";
                                ldeTotalCostAmtExpected := ldeTotalCostAmtExpected + lreValueEntry."Cost Amount (Expected) (ACY)";
                                if lreValueEntry."Cost per Unit" <> 0 then begin
                                    ldeTotalAmt :=
                                      lreValueEntry."Sales Amount (Actual)" * lreValueEntry."Cost per Unit (ACY)" / lreValueEntry."Cost per Unit";
                                    ldeTotalAmtExpected :=
                                      ldeTotalAmtExpected +
                                      lreValueEntry."Sales Amount (Expected)" * lreValueEntry."Cost per Unit (ACY)" / lreValueEntry."Cost per Unit";
                                end else begin
                                    ldeTotalAmt :=
                                      greCurrExchRate.ExchangeAmtLCYToFCY(
                                        lreValueEntry."Posting Date", greGLSetup."Additional Reporting Currency",
                                        lreValueEntry."Sales Amount (Actual)", gdeAddCurrencyFactor);
                                    ldeTotalAmtExpected :=
                                      ldeTotalAmtExpected +
                                      greCurrExchRate.ExchangeAmtLCYToFCY(
                                        lreValueEntry."Posting Date", greGLSetup."Additional Reporting Currency",
                                        lreValueEntry."Sales Amount (Expected)", gdeAddCurrencyFactor);
                                end;
                            end;
                        if (lreValueEntry."Item Ledger Entry Quantity" <> 0) and (lreValueEntry."Valued Quantity" = 0) then
                            linQuantityEntry := lreValueEntry."Entry No."
                        else
                            if greTBuffer.Get(lreValueEntry."Document No.") then begin
                                greTBuffer."Debit Amount" := greTBuffer."Debit Amount" + ldeTotalAmt;
                                greTBuffer."Credit Amount" := greTBuffer."Credit Amount" + ldeTotalCostAmt;
                                greTBuffer.Modify();
                            end else begin
                                greTBuffer.Init();
                                greTBuffer."Document No." := lreValueEntry."Document No.";
                                greTBuffer."Debit Amount" := ldeTotalAmt;
                                greTBuffer."Credit Amount" := ldeTotalCostAmt;
                                greTBuffer."Posting Date" := lreValueEntry."Posting Date";
                                greTBuffer.Insert();
                            end;
                    until lreValueEntry.Next() = 0;

                if ((ldeTotalAmtExpected <> 0) or (ldeTotalCostAmtExpected <> 0)) and (linQuantityEntry <> 0) then begin
                    lreValueEntry.Get(linQuantityEntry);
                    if greTBuffer.Get(lreValueEntry."Document No.") then begin
                        greTBuffer."Debit Amount" := greTBuffer."Debit Amount" + ldeTotalAmtExpected;
                        greTBuffer."Credit Amount" := greTBuffer."Credit Amount" + ldeTotalCostAmtExpected;
                        greTBuffer.Modify();
                    end else begin
                        greTBuffer.Init();
                        greTBuffer."Document No." := lreValueEntry."Document No.";
                        greTBuffer."Debit Amount" := ldeTotalAmtExpected;
                        greTBuffer."Credit Amount" := ldeTotalCostAmtExpected;
                        greTBuffer."Posting Date" := lreValueEntry."Posting Date";
                        greTBuffer.Insert();
                    end;
                end;
                if not greItemEntry.Get("Source Entry No.") then
                    greItemEntry.Init();
                gteDocType := DocumentType(greItemEntry."Document No.");

            end;

            trigger OnPreDataItem()
            var
                lteYear: Text[30];
                lteMonth: Text[30];
                linYear: Integer;
                linMonth: Integer;
            begin
                greGLSetup.Get();
                if not FindFirst() then
                    CurrReport.Break();

                greIntrastatJnlBatch.Get("Journal Template Name", "Journal Batch Name");
                lteYear := CopyStr(greIntrastatJnlBatch."Statistics Period", 1, 2);
                lteMonth := CopyStr(greIntrastatJnlBatch."Statistics Period", 3, 2);
                Evaluate(linYear, lteYear);
                Evaluate(linMonth, lteMonth);
                linYear := linYear + 2000;

                gdaStartDate := DMY2Date(1, linMonth, linYear);
                gdaEndDate := CalcDate('<CM>', gdaStartDate);
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

    var
        greGLSetup: Record "General Ledger Setup";
        greTBuffer: Record "G/L Account Adjustment Buffer" temporary;
        greIntrastatJnlBatch: Record "Intrastat Jnl. Batch";
        greCurrExchRate: Record "Currency Exchange Rate";
        greItemEntry: Record "Item Ledger Entry";
        gteDocType: Text[50];
        gdaStartDate: Date;
        gdaEndDate: Date;
        gdeAddCurrencyFactor: Decimal;
        Intrastat___Invoice_ChecklistCaptionLbl: Label 'Intrastat - Invoice Checklist';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        greTBuffer__Document_No__CaptionLbl: Label 'Document No.';
        greTBuffer_DescriptionCaptionLbl: Label 'Document Type';
        greTBuffer__Posting_Date_CaptionLbl: Label 'Date';

    [Scope('OnPrem')]
    procedure DocumentType(lcoDocNo: Code[20]): Text[50]
    var
        lreSShipment: Record "Sales Shipment Header";
        lreSInvoice: Record "Sales Invoice Header";
        lreSCreditMemo: Record "Sales Cr.Memo Header";
        lreSReturOrder: Record "Return Receipt Header";
        lrePShipment: Record "Purch. Rcpt. Header";
        lrePInvoice: Record "Purch. Inv. Header";
        lrePCreditMemo: Record "Purch. Cr. Memo Hdr.";
        lrePReturOrder: Record "Return Shipment Header";
        ltcText000: Label 'Sales Shipment';
        ltcText001: Label 'Sales Invoice';
        ltcText002: Label 'Sales Credit Memo';
        ltcText003: Label 'Sales Return';
        ltcText004: Label 'Purchase Shipment';
        ltcText005: Label 'Purchase Invoice';
        ltcText006: Label 'Purchase Credit Memo';
        ltcText007: Label 'Purchase Return';
    begin
        case true of
            lreSInvoice.Get(lcoDocNo):
                exit(ltcText001);
            lrePInvoice.Get(lcoDocNo):
                exit(ltcText005);
            lreSShipment.Get(lcoDocNo):
                exit(ltcText000);
            lrePShipment.Get(lcoDocNo):
                exit(ltcText004);
            lreSCreditMemo.Get(lcoDocNo):
                exit(ltcText002);
            lrePCreditMemo.Get(lcoDocNo):
                exit(ltcText006);
            lreSReturOrder.Get(lcoDocNo):
                exit(ltcText003);
            lrePReturOrder.Get(lcoDocNo):
                exit(ltcText007)
            else
                exit('');
        end;
    end;
}
#endif