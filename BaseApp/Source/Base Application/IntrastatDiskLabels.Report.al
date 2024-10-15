report 11000 "Intrastat  Disk (Labels)"
{
    DefaultLayout = RDLC;
    RDLCLayout = './IntrastatDiskLabels.rdlc';
    Caption = 'Intrastat  Disk (Labels)';

    dataset
    {
        dataitem("Intrastat Jnl. Batch"; "Intrastat Jnl. Batch")
        {
            DataItemTableView = SORTING("Journal Template Name", Name);
            RequestFilterFields = "Journal Template Name", Name;
            column(Intrastat_Jnl__Batch_Journal_Template_Name; "Journal Template Name")
            {
            }
            column(Intrastat_Jnl__Batch_Name; Name)
            {
            }
            dataitem("Company Information"; "Company Information")
            {
                DataItemTableView = SORTING("Primary Key");
                MaxIteration = 1;
                column(Company_Information_Name; Name)
                {
                }
                column(Company_Information__Purch__Authorized_No__; "Purch. Authorized No.")
                {
                }
                column(Intrastat_Purch__Rep__Month_; IntrastatPurchRepMonth)
                {
                }
                column(RecordsPurchase; RecordsPurchase)
                {
                }
                column(Intrastat_Purch__Amount_; IntrastatPurchAmount)
                {
                }
                column(Intrastat_Purch__Statistical_; IntrastatPurchStatistical)
                {
                }
                column(Company_Information_Name_Control1140013; Name)
                {
                }
                column(Company_Information__Sales_Authorized_No__; "Sales Authorized No.")
                {
                }
                column(Intrastat_Sales_Rep__Month_; IntrastatSalesRepMonth)
                {
                }
                column(RecordsSales; RecordsSales)
                {
                }
                column(Intrastat_Sales_Amount_; IntrastatSalesAmount)
                {
                }
                column(Intrastat_Sales_Statistical_; IntrastatSalesStatistical)
                {
                }
                column(Text1140005___ShowCurrency; Text1140005 + ShowCurrency)
                {
                }
                column(Text1140006___ShowCurrency; Text1140006 + ShowCurrency)
                {
                }
                column(Text1140007___ShowCurrency; Text1140007 + ShowCurrency)
                {
                }
                column(Text1140008___ShowCurrency; Text1140008 + ShowCurrency)
                {
                }
                column(FORMAT_Area_2____PADSTR_VATIDNo_11__0_____FORMAT__Agency_No___3_; Format(Area, 2) + PadStr(VATIDNo, 11, '0') + Format("Agency No.", 3))
                {
                }
                column(FORMAT_Area_2____PADSTR_VATIDNo_11__0_____FORMAT__Agency_No___3__Control1140029; Format(Area, 2) + PadStr(VATIDNo, 11, '0') + Format("Agency No.", 3))
                {
                }
                column(Company_Information_Primary_Key; "Primary Key")
                {
                }
                column(Identification_No_Caption; Identification_No_CaptionLbl)
                {
                }
                column(Company_NameCaption; Company_NameCaptionLbl)
                {
                }
                column(ReceiptCaption; ReceiptCaptionLbl)
                {
                }
                column(Authorized_No_Caption; Authorized_No_CaptionLbl)
                {
                }
                column(Reporting_MonthCaption; Reporting_MonthCaptionLbl)
                {
                }
                column(No__of_RecordCaption; No__of_RecordCaptionLbl)
                {
                }
                column(Identification_No_Caption_Control1140012; Identification_No_Caption_Control1140012Lbl)
                {
                }
                column(Company_NameCaption_Control1140014; Company_NameCaption_Control1140014Lbl)
                {
                }
                column(ShipmentCaption; ShipmentCaptionLbl)
                {
                }
                column(Authorized_No_Caption_Control1140017; Authorized_No_Caption_Control1140017Lbl)
                {
                }
                column(Reporting_MonthCaption_Control1140019; Reporting_MonthCaption_Control1140019Lbl)
                {
                }
                column(No__of_RecordCaption_Control1140021; No__of_RecordCaption_Control1140021Lbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    TestField("Registration No.");
                    VATIDNo := CopyStr(DelChr(UpperCase("Company Information"."Registration No."), '=', Text1140000), 1, 11);

                    FileName := "Purch. Authorized No." + Text1140002;
                    if not Upload(FileName, '', '', FileName, FileName) then
                        CurrReport.Quit;

                    IntraFile.TextMode := true;
                    IntraFile.WriteMode := false;
                    IntraFile.Open(FileName);
                    while IntraFile.Read(ReadString) > 1 do begin
                        RecordsPurchase := RecordsPurchase + 1;
                        if Evaluate(Decimal, CopyStr(ReadString, 95, 11)) then
                            IntrastatPurchAmount := IntrastatPurchAmount + Decimal;
                        if Evaluate(Decimal, CopyStr(ReadString, 106, 11)) then
                            IntrastatPurchStatistical := IntrastatPurchStatistical + Decimal;
                        IntrastatPurchRepMonth := CopyStr(ReadString, 3, 2);
                    end;
                    IntraFile.Close;
                    FileName := "Sales Authorized No." + Text1140002;
                    if not Upload(FileName, '', '', FileName, FileName) then
                        CurrReport.Quit;

                    IntraFile.TextMode := true;
                    IntraFile.WriteMode := false;
                    IntraFile.Open(FileName);
                    while IntraFile.Read(ReadString) > 1 do begin
                        RecordsSales := RecordsSales + 1;
                        if Evaluate(Decimal, CopyStr(ReadString, 95, 11)) then
                            IntrastatSalesAmount := IntrastatSalesAmount + Decimal;
                        if Evaluate(Decimal, CopyStr(ReadString, 106, 11)) then
                            IntrastatSalesStatistical := IntrastatSalesStatistical + Decimal;
                        IntrastatSalesRepMonth := CopyStr(ReadString, 4, 2);
                    end;
                    IntraFile.Close;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                RecordsPurchase := 0;
                IntrastatPurchAmount := 0;
                IntrastatPurchStatistical := 0;
                RecordsSales := 0;
                IntrastatSalesAmount := 0;
                IntrastatSalesStatistical := 0;
            end;

            trigger OnPreDataItem()
            begin
                GLSetup.Get();
                if "Intrastat Jnl. Batch"."Amounts in Add. Currency" then begin
                    GLSetup.TestField("Additional Reporting Currency");
                    ShowCurrency := GLSetup."Additional Reporting Currency";
                end else begin
                    GLSetup.TestField("LCY Code");
                    ShowCurrency := GLSetup."LCY Code";
                end;
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

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
        Text1140000: Label 'ABCDEFGHIJKLMNOPQRSTUVWXYZ/-.+';
        Text1140002: Label '.ASC';
        Text1140005: Label 'Total Purch. Amount in ';
        Text1140006: Label 'Total Purch. Statistical Amount in ';
        Text1140007: Label 'Total Sales Amount in ';
        Text1140008: Label 'Total Sales Statistical Amount in ';
        GLSetup: Record "General Ledger Setup";
        IntraFile: File;
        VATIDNo: Code[11];
        FileName: Text;
        ShowCurrency: Code[10];
        ReadString: Text[128];
        RecordsPurchase: Integer;
        RecordsSales: Integer;
        IntrastatPurchRepMonth: Code[2];
        IntrastatSalesRepMonth: Code[2];
        IntrastatPurchAmount: Decimal;
        IntrastatSalesAmount: Decimal;
        IntrastatPurchStatistical: Decimal;
        IntrastatSalesStatistical: Decimal;
        Decimal: Decimal;
        Identification_No_CaptionLbl: Label 'Identification No.';
        Company_NameCaptionLbl: Label 'Company Name';
        ReceiptCaptionLbl: Label 'Receipt';
        Authorized_No_CaptionLbl: Label 'Authorized No.';
        Reporting_MonthCaptionLbl: Label 'Reporting Month';
        No__of_RecordCaptionLbl: Label 'No. of Record';
        Identification_No_Caption_Control1140012Lbl: Label 'Identification No.';
        Company_NameCaption_Control1140014Lbl: Label 'Company Name';
        ShipmentCaptionLbl: Label 'Shipment';
        Authorized_No_Caption_Control1140017Lbl: Label 'Authorized No.';
        Reporting_MonthCaption_Control1140019Lbl: Label 'Reporting Month';
        No__of_RecordCaption_Control1140021Lbl: Label 'No. of Record';
}

