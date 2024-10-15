report 12161 "Intrastat - Quarterly Report"
{
    DefaultLayout = RDLC;
    RDLCLayout = './IntrastatQuarterlyReport.rdlc';
    Caption = 'Intrastat - Quarterly Report';

    dataset
    {
        dataitem("Intrastat Jnl. Batch"; "Intrastat Jnl. Batch")
        {
            DataItemTableView = SORTING("Journal Template Name", Name);
            column(Intrastat_Jnl__Batch_Journal_Template_Name; "Journal Template Name")
            {
            }
            column(Intrastat_Jnl__Batch_Name; Name)
            {
            }
            dataitem("Intrastat Jnl. Line"; "Intrastat Jnl. Line")
            {
                DataItemLink = "Journal Template Name" = FIELD("Journal Template Name"), "Journal Batch Name" = FIELD(Name);
                DataItemTableView = SORTING(Type, "Country/Region Code", "Partner VAT ID", "Transaction Type", "Tariff No.", "Group Code", "Transport Method", "Transaction Specification", "Country/Region of Origin Code", Area, "Corrective entry") ORDER(Ascending);
                RequestFilterFields = "Journal Template Name", "Journal Batch Name";
                column(STRSUBSTNO_Text001__Intrastat_Jnl__Batch___Statistics_Period__; StrSubstNo(Text001, "Intrastat Jnl. Batch"."Statistics Period"))
                {
                }
                column(COMPANYNAME; COMPANYPROPERTY.DisplayName)
                {
                }
                column(CompanyInfo__VAT_Registration_No__; CompanyInfo."VAT Registration No.")
                {
                }
                column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
                {
                }
                column(USERID; UserId)
                {
                }
                column(Intrastat_Jnl__Line__Intrastat_Jnl__Line___Type; "Intrastat Jnl. Line".Type)
                {
                }
                column(Intrastat_Jnl__Batch___Corrective_Entry_; "Intrastat Jnl. Batch"."Corrective Entry")
                {
                }
                column(Intrastat_Jnl__Batch___EU_Service_; "Intrastat Jnl. Batch"."EU Service")
                {
                }
                column(Sales; Sales)
                {
                }
                column(NoOfRecords_Control1130002; NoOfRecords)
                {
                }
                column(Intrastat_Jnl__Line__Country_Region_Code_; "Country/Region Code")
                {
                }
                column(Intrastat_Jnl__Line__VAT_Registration_No__; "Partner VAT ID")
                {
                }
                column(RoundAmount_Control1130036; RoundAmount)
                {
                    DecimalPlaces = 0 : 0;
                }
                column(Intrastat_Jnl__Line__Document_No__; "Document No.")
                {
                }
                column(Intrastat_Jnl__Line_Date; Format(Date))
                {
                }
                column(Intrastat_Jnl__Line__Service_Tariff_No__; "Service Tariff No.")
                {
                }
                column(Intrastat_Jnl__Line__Transport_Method_; "Transport Method")
                {
                }
                column(Intrastat_Jnl__Line__Payment_Method_; PaymentMethod."Intrastat Payment Method")
                {
                }
                column(Intrastat_Jnl__Line__Country_Region_Code__Control1130048; "Country/Region Code")
                {
                }
                column(NoOfRecords_Control1130050; NoOfRecords)
                {
                }
                column(Intrastat_Jnl__Line__Country_Region_Code__Control1130052; "Country/Region Code")
                {
                }
                column(Intrastat_Jnl__Line__VAT_Registration_No___Control1130054; "Partner VAT ID")
                {
                }
                column(RoundAmount_Control1130056; RoundAmount)
                {
                    DecimalPlaces = 0 : 0;
                }
                column(Intrastat_Jnl__Line__Source_Currency_Amount_; "Source Currency Amount")
                {
                }
                column(Intrastat_Jnl__Line__Document_No___Control1130060; "Document No.")
                {
                }
                column(Intrastat_Jnl__Line_Date_Control1130062; Format(Date))
                {
                }
                column(Intrastat_Jnl__Line__Service_Tariff_No___Control1130064; "Service Tariff No.")
                {
                }
                column(Intrastat_Jnl__Line__Transport_Method__Control1130066; "Transport Method")
                {
                }
                column(Intrastat_Jnl__Line__Payment_Method__Control1130068; PaymentMethod."Intrastat Payment Method")
                {
                }
                column(Intrastat_Jnl__Line__Country_Region_of_Payment_Code_; "Country/Region of Payment Code")
                {
                }
                column(NoOfRecords_Control1130072; NoOfRecords)
                {
                }
                column(Intrastat_Jnl__Line__Custom_Office_No__; "Custom Office No.")
                {
                }
                column(Intrastat_Jnl__Line__Reference_Period_; "Reference Period")
                {
                }
                column(Intrastat_Jnl__Line__Corrected_Intrastat_Report_No__; "Corrected Intrastat Report No.")
                {
                }
                column(Intrastat_Jnl__Line__Corrected_Document_No__; "Corrected Document No.")
                {
                }
                column(Intrastat_Jnl__Line__VAT_Registration_No___Control1130084; "Partner VAT ID")
                {
                }
                column(RoundAmount_Control1130086; RoundAmount)
                {
                    DecimalPlaces = 0 : 0;
                }
                column(Intrastat_Jnl__Line__Document_No___Control1130088; "Document No.")
                {
                }
                column(Intrastat_Jnl__Line__Service_Tariff_No___Control1130092; "Service Tariff No.")
                {
                }
                column(Intrastat_Jnl__Line__Transport_Method__Control1130094; "Transport Method")
                {
                }
                column(Intrastat_Jnl__Line__Payment_Method__Control1130096; PaymentMethod."Intrastat Payment Method")
                {
                }
                column(Intrastat_Jnl__Line__Country_Region_Code__Control1130098; "Country/Region Code")
                {
                }
                column(Intrastat_Jnl__Line__Country_Region_Code__Control1130134; "Country/Region Code")
                {
                }
                column(Intrastat_Jnl__Line_Date_Control1130136; Format(Date))
                {
                }
                column(NoOfRecords_Control1130101; NoOfRecords)
                {
                }
                column(Intrastat_Jnl__Line__Custom_Office_No___Control1130103; "Custom Office No.")
                {
                }
                column(Intrastat_Jnl__Line__Reference_Period__Control1130105; "Reference Period")
                {
                }
                column(Intrastat_Jnl__Line__Corrected_Intrastat_Report_No___Control1130107; "Corrected Intrastat Report No.")
                {
                }
                column(Intrastat_Jnl__Line__Corrected_Document_No___Control1130109; "Corrected Document No.")
                {
                }
                column(Intrastat_Jnl__Line__Country_Region_Code__Control1130111; "Country/Region Code")
                {
                }
                column(Intrastat_Jnl__Line__VAT_Registration_No___Control1130113; "Partner VAT ID")
                {
                }
                column(RoundAmount_Control1130115; RoundAmount)
                {
                    DecimalPlaces = 0 : 0;
                }
                column(Intrastat_Jnl__Line__Document_No___Control1130117; "Document No.")
                {
                }
                column(Intrastat_Jnl__Line__Service_Tariff_No___Control1130121; "Service Tariff No.")
                {
                }
                column(Intrastat_Jnl__Line__Source_Currency_Amount__Control1130123; "Source Currency Amount")
                {
                }
                column(Intrastat_Jnl__Line__Transport_Method__Control1130125; "Transport Method")
                {
                }
                column(Intrastat_Jnl__Line__Payment_Method__Control1130127; PaymentMethod."Intrastat Payment Method")
                {
                }
                column(Intrastat_Jnl__Line__Country_Region_of_Payment_Code__Control1130129; "Country/Region of Payment Code")
                {
                }
                column(Intrastat_Jnl__Line_Date_Control1130138; Format(Date))
                {
                }
                column(RoundAmount_Control1130119; RoundAmount)
                {
                    DecimalPlaces = 0 : 0;
                }
                column(RoundAmount_Control1130132; RoundAmount)
                {
                    DecimalPlaces = 0 : 0;
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
                column(Intrastat___Quarterly_ReportCaption; Intrastat___Quarterly_ReportCaptionLbl)
                {
                }
                column(CompanyInfo__VAT_Registration_No__Caption; CompanyInfo__VAT_Registration_No__CaptionLbl)
                {
                }
                column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
                {
                }
                column(NoOfRecords_Control1130002Caption; NoOfRecords_Control1130002CaptionLbl)
                {
                }
                column(Intrastat_Jnl__Line__Country_Region_Code_Caption; FieldCaption("Country/Region Code"))
                {
                }
                column(Intrastat_Jnl__Line__VAT_Registration_No__Caption; FieldCaption("VAT Registration No."))
                {
                }
                column(RoundAmount_Control1130036Caption; RoundAmount_Control1130036CaptionLbl)
                {
                }
                column(Intrastat_Jnl__Line__Document_No__Caption; FieldCaption("Document No."))
                {
                }
                column(Intrastat_Jnl__Line_DateCaption; Intrastat_Jnl__Line_DateCaptionLbl)
                {
                }
                column(Intrastat_Jnl__Line__Service_Tariff_No__Caption; Intrastat_Jnl__Line__Service_Tariff_No__CaptionLbl)
                {
                }
                column(Intrastat_Jnl__Line__Transport_Method_Caption; Intrastat_Jnl__Line__Transport_Method_CaptionLbl)
                {
                }
                column(Intrastat_Jnl__Line__Payment_Method_Caption; Intrastat_Jnl__Line__Payment_Method_CaptionLbl)
                {
                }
                column(Intrastat_Jnl__Line__Country_Region_Code__Control1130048Caption; Intrastat_Jnl__Line__Country_Region_Code__Control1130048CaptionLbl)
                {
                }
                column(NoOfRecords_Control1130050Caption; NoOfRecords_Control1130050CaptionLbl)
                {
                }
                column(Intrastat_Jnl__Line__Country_Region_Code__Control1130052Caption; FieldCaption("Country/Region Code"))
                {
                }
                column(Intrastat_Jnl__Line__VAT_Registration_No___Control1130054Caption; FieldCaption("VAT Registration No."))
                {
                }
                column(RoundAmount_Control1130056Caption; RoundAmount_Control1130056CaptionLbl)
                {
                }
                column(Intrastat_Jnl__Line__Source_Currency_Amount_Caption; Intrastat_Jnl__Line__Source_Currency_Amount_CaptionLbl)
                {
                }
                column(Intrastat_Jnl__Line__Document_No___Control1130060Caption; FieldCaption("Document No."))
                {
                }
                column(Intrastat_Jnl__Line_Date_Control1130062Caption; Intrastat_Jnl__Line_Date_Control1130062CaptionLbl)
                {
                }
                column(Intrastat_Jnl__Line__Service_Tariff_No___Control1130064Caption; Intrastat_Jnl__Line__Service_Tariff_No___Control1130064CaptionLbl)
                {
                }
                column(Intrastat_Jnl__Line__Transport_Method__Control1130066Caption; Intrastat_Jnl__Line__Transport_Method__Control1130066CaptionLbl)
                {
                }
                column(Intrastat_Jnl__Line__Payment_Method__Control1130068Caption; Intrastat_Jnl__Line__Payment_Method__Control1130068CaptionLbl)
                {
                }
                column(Intrastat_Jnl__Line__Country_Region_of_Payment_Code_Caption; Intrastat_Jnl__Line__Country_Region_of_Payment_Code_CaptionLbl)
                {
                }
                column(NoOfRecords_Control1130072Caption; NoOfRecords_Control1130072CaptionLbl)
                {
                }
                column(Intrastat_Jnl__Line__Custom_Office_No__Caption; Intrastat_Jnl__Line__Custom_Office_No__CaptionLbl)
                {
                }
                column(Intrastat_Jnl__Line__Reference_Period_Caption; Intrastat_Jnl__Line__Reference_Period_CaptionLbl)
                {
                }
                column(Intrastat_Jnl__Line__Corrected_Intrastat_Report_No__Caption; Intrastat_Jnl__Line__Corrected_Intrastat_Report_No__CaptionLbl)
                {
                }
                column(Intrastat_Jnl__Line__Corrected_Document_No__Caption; FieldCaption("Corrected Document No."))
                {
                }
                column(Intrastat_Jnl__Line__VAT_Registration_No___Control1130084Caption; FieldCaption("VAT Registration No."))
                {
                }
                column(RoundAmount_Control1130086Caption; RoundAmount_Control1130086CaptionLbl)
                {
                }
                column(Intrastat_Jnl__Line__Document_No___Control1130088Caption; FieldCaption("Document No."))
                {
                }
                column(Intrastat_Jnl__Line__Service_Tariff_No___Control1130092Caption; Intrastat_Jnl__Line__Service_Tariff_No___Control1130092CaptionLbl)
                {
                }
                column(Intrastat_Jnl__Line__Transport_Method__Control1130094Caption; Intrastat_Jnl__Line__Transport_Method__Control1130094CaptionLbl)
                {
                }
                column(Intrastat_Jnl__Line__Payment_Method__Control1130096Caption; Intrastat_Jnl__Line__Payment_Method__Control1130096CaptionLbl)
                {
                }
                column(Intrastat_Jnl__Line__Country_Region_Code__Control1130098Caption; Intrastat_Jnl__Line__Country_Region_Code__Control1130098CaptionLbl)
                {
                }
                column(Intrastat_Jnl__Line__Country_Region_Code__Control1130134Caption; FieldCaption("Country/Region Code"))
                {
                }
                column(Intrastat_Jnl__Line_Date_Control1130136Caption; Intrastat_Jnl__Line_Date_Control1130136CaptionLbl)
                {
                }
                column(NoOfRecords_Control1130101Caption; NoOfRecords_Control1130101CaptionLbl)
                {
                }
                column(Intrastat_Jnl__Line__Custom_Office_No___Control1130103Caption; Intrastat_Jnl__Line__Custom_Office_No___Control1130103CaptionLbl)
                {
                }
                column(Intrastat_Jnl__Line__Reference_Period__Control1130105Caption; Intrastat_Jnl__Line__Reference_Period__Control1130105CaptionLbl)
                {
                }
                column(Intrastat_Jnl__Line__Corrected_Intrastat_Report_No___Control1130107Caption; Intrastat_Jnl__Line__Corrected_Intrastat_Report_No___Control1130107CaptionLbl)
                {
                }
                column(Intrastat_Jnl__Line__Corrected_Document_No___Control1130109Caption; FieldCaption("Corrected Document No."))
                {
                }
                column(Intrastat_Jnl__Line__Country_Region_Code__Control1130111Caption; FieldCaption("Country/Region Code"))
                {
                }
                column(Intrastat_Jnl__Line__VAT_Registration_No___Control1130113Caption; FieldCaption("VAT Registration No."))
                {
                }
                column(RoundAmount_Control1130115Caption; RoundAmount_Control1130115CaptionLbl)
                {
                }
                column(Intrastat_Jnl__Line__Document_No___Control1130117Caption; FieldCaption("Document No."))
                {
                }
                column(Intrastat_Jnl__Line__Service_Tariff_No___Control1130121Caption; Intrastat_Jnl__Line__Service_Tariff_No___Control1130121CaptionLbl)
                {
                }
                column(Intrastat_Jnl__Line__Source_Currency_Amount__Control1130123Caption; Intrastat_Jnl__Line__Source_Currency_Amount__Control1130123CaptionLbl)
                {
                }
                column(Intrastat_Jnl__Line__Transport_Method__Control1130125Caption; Intrastat_Jnl__Line__Transport_Method__Control1130125CaptionLbl)
                {
                }
                column(Intrastat_Jnl__Line__Payment_Method__Control1130127Caption; Intrastat_Jnl__Line__Payment_Method__Control1130127CaptionLbl)
                {
                }
                column(Intrastat_Jnl__Line__Country_Region_of_Payment_Code__Control1130129Caption; Intrastat_Jnl__Line__Country_Region_of_Payment_Code__Control1130129CaptionLbl)
                {
                }
                column(Intrastat_Jnl__Line_Date_Control1130138Caption; Intrastat_Jnl__Line_Date_Control1130138CaptionLbl)
                {
                }
                column(RoundAmount_Control1130119Caption; RoundAmount_Control1130119CaptionLbl)
                {
                }
                column(RoundAmount_Control1130132Caption; RoundAmount_Control1130132CaptionLbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if "Intrastat Jnl. Batch"."EU Service" then begin
                        TestField("Partner VAT ID");
                        TestField("Country/Region Code");
                        TestField("Service Tariff No.");
                        NoOfRecords := NoOfRecords + 1;
                        RoundAmount := Round(Amount, 1);
                        GetPaymentMethod;
                    end else begin
                        if ("Tariff No." = '') and
                           ("Partner VAT ID" = '') and
                           ("Transaction Type" = '') and
                           ("Total Weight" = 0)
                        then
                            CurrReport.Skip();

                        TestField("Partner VAT ID");
                        TestField("Transaction Type");
                        TestField("Tariff No.");
                        TestField("Country/Region Code");

                        if "Supplementary Units" then
                            TestField(Quantity);
                        Country.Get("Country/Region Code");

                        IntrastatJnlLineTemp.Reset();
                        IntrastatJnlLineTemp.SetRange(Type, Type);
                        IntrastatJnlLineTemp.SetRange("Tariff No.", "Tariff No.");
                        IntrastatJnlLineTemp.SetRange("Country/Region Code", "Country/Region Code");
                        IntrastatJnlLineTemp.SetRange("Transaction Type", "Transaction Type");
                        IntrastatJnlLineTemp.SetRange("Transport Method", "Transport Method");
                        if not IntrastatJnlLineTemp.FindFirst then begin
                            IntrastatJnlLineTemp := "Intrastat Jnl. Line";
                            IntrastatJnlLineTemp.Insert();
                            NoOfRecordsRTC += 1;
                        end;

                        "Intra - form Buffer".Reset();

                        if "Intra - form Buffer".Get("Partner VAT ID", "Intrastat Jnl. Line"."Transaction Type",
                             "Intrastat Jnl. Line"."Tariff No.", '', '', '', '', '', "Intrastat Jnl. Line"."Corrective entry")
                        then begin
                            "Intra - form Buffer".Amount := "Intra - form Buffer".Amount + "Intrastat Jnl. Line".Amount;
                            "Intra - form Buffer"."Source Currency Amount" := "Intra - form Buffer"."Source Currency Amount" +
                              "Intrastat Jnl. Line"."Source Currency Amount";
                            "Intra - form Buffer".Modify();
                        end else begin
                            "Intra - form Buffer".TransferFields("Intrastat Jnl. Line");
                            "Intra - form Buffer"."VAT Registration No." :=
                              CopyStr("Partner VAT ID", 1, MaxStrLen("Intra - form Buffer"."VAT Registration No."));
                            "Intra - form Buffer"."User ID" := UserId;
                            "Intra - form Buffer"."Group Code" := '';
                            "Intra - form Buffer"."Transport Method" := '';
                            "Intra - form Buffer"."Transaction Specification" := '';
                            "Intra - form Buffer"."Country/Region of Origin Code" := '';
                            "Intra - form Buffer".Area := '';
                            "Intra - form Buffer"."No." := 0;
                            "Intra - form Buffer".Insert();
                        end;
                    end;
                end;

                trigger OnPreDataItem()
                begin
                    IntrastatJnlLineTemp.DeleteAll();
                    NoOfRecordsRTC := 0;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                Sales := "Intrastat Jnl. Batch".Type = "Intrastat Jnl. Batch".Type::Sales;
            end;

            trigger OnPreDataItem()
            begin
                SetFilter("Journal Template Name", "Intrastat Jnl. Line".GetFilter("Journal Template Name"));
                SetFilter(Name, BatchNameFilter);
            end;
        }
        dataitem("Intra - form Buffer"; "Intra - form Buffer")
        {
            DataItemTableView = SORTING("VAT Registration No.", "Transaction Type", "Tariff No.", "Group Code", "Transport Method", "Transaction Specification", "Country/Region of Origin Code", Area, "Corrective entry") ORDER(Ascending);
            column(Sales_Old; Sales)
            {
            }
            column(Intra___form_Buffer__Country_code_; "Country/Region Code")
            {
            }
            column(Intra___form_Buffer__VAT_Registration_No__; "VAT Registration No.")
            {
            }
            column(RoundAmount; RoundAmount)
            {
                AutoFormatType = 0;
                DecimalPlaces = 0 : 0;
            }
            column(Intra___form_Buffer__Transaction_Type_; "Transaction Type")
            {
            }
            column(Intra___form_Buffer__Tariff_No__; "Tariff No.")
            {
            }
            column(NoOfRecords; NoOfRecords)
            {
            }
            column(NoOfRecords_Control1130013; NoOfRecords)
            {
            }
            column(Intra___form_Buffer__Country_code__Control1130014; "Country/Region Code")
            {
            }
            column(Intra___form_Buffer__VAT_Registration_No___Control1130015; "VAT Registration No.")
            {
            }
            column(RoundAmount_Control1130016; RoundAmount)
            {
                AutoFormatType = 0;
                DecimalPlaces = 0 : 0;
            }
            column(Intra___form_Buffer__Source_Currency_Amount_; "Source Currency Amount")
            {
                AutoFormatType = 0;
                DecimalPlaces = 0 : 0;
            }
            column(Intra___form_Buffer__Tariff_No___Control1130019; "Tariff No.")
            {
            }
            column(Intra___form_Buffer__Transaction_Type__Control1130018; "Transaction Type")
            {
            }
            column(TotRoundAmount; TotRoundAmount)
            {
                AutoFormatType = 0;
                DecimalPlaces = 0 : 0;
            }
            column(Intra___form_Buffer_Group_Code; "Group Code")
            {
            }
            column(Intra___form_Buffer_Transport_Method; "Transport Method")
            {
            }
            column(Intra___form_Buffer_Transaction_Specification; "Transaction Specification")
            {
            }
            column(Intra___form_Buffer_Country_of_Origin_Code; "Country/Region of Origin Code")
            {
            }
            column(Intra___form_Buffer_Area; Area)
            {
            }
            column(Intra___form_Buffer_Corrective_entry; "Corrective entry")
            {
            }
            column(Intra___form_Buffer_No_; "No.")
            {
            }
            column(Intra___form_Buffer__VAT_Registration_No__Caption; Intra___form_Buffer__VAT_Registration_No__CaptionLbl)
            {
            }
            column(Intra___form_Buffer__Country_code_Caption; Intra___form_Buffer__Country_code_CaptionLbl)
            {
            }
            column(RoundAmountCaption; RoundAmountCaptionLbl)
            {
            }
            column(Intra___form_Buffer__Transaction_Type_Caption; Intra___form_Buffer__Transaction_Type_CaptionLbl)
            {
            }
            column(Intra___form_Buffer__Tariff_No__Caption; Intra___form_Buffer__Tariff_No__CaptionLbl)
            {
            }
            column(NoOfRecordsCaption; NoOfRecordsCaptionLbl)
            {
            }
            column(Intra___form_Buffer__Transaction_Type__Control1130018Caption; Intra___form_Buffer__Transaction_Type__Control1130018CaptionLbl)
            {
            }
            column(Intra___form_Buffer__Source_Currency_Amount_Caption; Intra___form_Buffer__Source_Currency_Amount_CaptionLbl)
            {
            }
            column(RoundAmount_Control1130016Caption; RoundAmount_Control1130016CaptionLbl)
            {
            }
            column(Intra___form_Buffer__VAT_Registration_No___Control1130015Caption; Intra___form_Buffer__VAT_Registration_No___Control1130015CaptionLbl)
            {
            }
            column(Intra___form_Buffer__Country_code__Control1130014Caption; Intra___form_Buffer__Country_code__Control1130014CaptionLbl)
            {
            }
            column(NoOfRecords_Control1130013Caption; NoOfRecords_Control1130013CaptionLbl)
            {
            }
            column(Intra___form_Buffer__Tariff_No___Control1130019Caption; Intra___form_Buffer__Tariff_No___Control1130019CaptionLbl)
            {
            }
            column(TotRoundAmountCaption; TotRoundAmountCaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                NoOfRecords := NoOfRecords + 1;
                RoundAmount := Round(Amount, 1);
                TotRoundAmount := TotRoundAmount + RoundAmount;
            end;

            trigger OnPreDataItem()
            begin
                if "Intrastat Jnl. Batch"."EU Service" then
                    CurrReport.Break();
                NoOfRecords := 0;
                TotRoundAmount := 0;
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
        "Intra - form Buffer".Reset();
        "Intra - form Buffer".SetFilter("User ID", UserId);
        "Intra - form Buffer".DeleteAll();
    end;

    trigger OnPreReport()
    begin
        BatchNameFilter := "Intrastat Jnl. Line".GetFilter("Journal Batch Name");
        "Intrastat Jnl. Line".Type := "Intrastat Jnl. Batch".Type;
        CompanyInfo.Get();
        CompanyInfo."VAT Registration No." := ConvertStr(CompanyInfo."VAT Registration No.", Text000, '    ');

        "Intra - form Buffer".Reset();
        "Intra - form Buffer".SetFilter("User ID", UserId);
        "Intra - form Buffer".DeleteAll();
    end;

    var
        Text000: Label 'WwWw';
        Text001: Label 'Statistics Period: %1';
        Text002: Label 'All amounts are in %1';
        CompanyInfo: Record "Company Information";
        Country: Record "Country/Region";
        IntrastatJnlLineTemp: Record "Intrastat Jnl. Line" temporary;
        PaymentMethod: Record "Payment Method";
        NoOfRecords: Integer;
        NoOfRecordsRTC: Integer;
        Sales: Boolean;
        RoundAmount: Decimal;
        TotRoundAmount: Decimal;
        BatchNameFilter: Text;
        Intrastat___Quarterly_ReportCaptionLbl: Label 'Intrastat - Quarterly Report';
        CompanyInfo__VAT_Registration_No__CaptionLbl: Label 'VAT Reg. No.';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        NoOfRecords_Control1130002CaptionLbl: Label 'Prog.';
        RoundAmount_Control1130036CaptionLbl: Label 'Amount';
        Intrastat_Jnl__Line_DateCaptionLbl: Label 'Date';
        Intrastat_Jnl__Line__Service_Tariff_No__CaptionLbl: Label 'Service Tariff Code';
        Intrastat_Jnl__Line__Transport_Method_CaptionLbl: Label 'Transport Method Code';
        Intrastat_Jnl__Line__Payment_Method_CaptionLbl: Label 'Payment Method Code';
        Intrastat_Jnl__Line__Country_Region_Code__Control1130048CaptionLbl: Label 'Payment Country/Region Code';
        NoOfRecords_Control1130050CaptionLbl: Label 'Prog.';
        RoundAmount_Control1130056CaptionLbl: Label 'Amount';
        Intrastat_Jnl__Line__Source_Currency_Amount_CaptionLbl: Label 'Amount in Src. Currency';
        Intrastat_Jnl__Line_Date_Control1130062CaptionLbl: Label 'Date';
        Intrastat_Jnl__Line__Service_Tariff_No___Control1130064CaptionLbl: Label 'Service Tariff Code';
        Intrastat_Jnl__Line__Transport_Method__Control1130066CaptionLbl: Label 'Transport Method Code';
        Intrastat_Jnl__Line__Payment_Method__Control1130068CaptionLbl: Label 'Payment Method Code';
        Intrastat_Jnl__Line__Country_Region_of_Payment_Code_CaptionLbl: Label 'Payment Country/Region Code';
        NoOfRecords_Control1130072CaptionLbl: Label 'Prog.';
        Intrastat_Jnl__Line__Custom_Office_No__CaptionLbl: Label 'Customs Office No.';
        Intrastat_Jnl__Line__Reference_Period_CaptionLbl: Label 'Year';
        Intrastat_Jnl__Line__Corrected_Intrastat_Report_No__CaptionLbl: Label 'Corrected Intrastat Report';
        RoundAmount_Control1130086CaptionLbl: Label 'Amount';
        Intrastat_Jnl__Line__Service_Tariff_No___Control1130092CaptionLbl: Label 'Service Tariff Code';
        Intrastat_Jnl__Line__Transport_Method__Control1130094CaptionLbl: Label 'Transport Method Code';
        Intrastat_Jnl__Line__Payment_Method__Control1130096CaptionLbl: Label 'Payment Method Code';
        Intrastat_Jnl__Line__Country_Region_Code__Control1130098CaptionLbl: Label 'Payment Country/Region Code';
        Intrastat_Jnl__Line_Date_Control1130136CaptionLbl: Label 'Date';
        NoOfRecords_Control1130101CaptionLbl: Label 'Prog.';
        Intrastat_Jnl__Line__Custom_Office_No___Control1130103CaptionLbl: Label 'Customs Office No.';
        Intrastat_Jnl__Line__Reference_Period__Control1130105CaptionLbl: Label 'Year';
        Intrastat_Jnl__Line__Corrected_Intrastat_Report_No___Control1130107CaptionLbl: Label 'Corrected Intrastat Report';
        RoundAmount_Control1130115CaptionLbl: Label 'Amount';
        Intrastat_Jnl__Line__Service_Tariff_No___Control1130121CaptionLbl: Label 'Service Tariff Code';
        Intrastat_Jnl__Line__Source_Currency_Amount__Control1130123CaptionLbl: Label 'Amount in Src. Currency';
        Intrastat_Jnl__Line__Transport_Method__Control1130125CaptionLbl: Label 'Transport Method Code';
        Intrastat_Jnl__Line__Payment_Method__Control1130127CaptionLbl: Label 'Payment Method Code';
        Intrastat_Jnl__Line__Country_Region_of_Payment_Code__Control1130129CaptionLbl: Label 'Payment Country/Region Code';
        Intrastat_Jnl__Line_Date_Control1130138CaptionLbl: Label 'Date';
        RoundAmount_Control1130119CaptionLbl: Label 'Total Amount';
        RoundAmount_Control1130132CaptionLbl: Label 'Total Amount';
        Intra___form_Buffer__VAT_Registration_No__CaptionLbl: Label 'VAT Registration No.';
        Intra___form_Buffer__Country_code_CaptionLbl: Label 'Country/Region code';
        RoundAmountCaptionLbl: Label 'Amount';
        Intra___form_Buffer__Transaction_Type_CaptionLbl: Label 'Transaction Type';
        Intra___form_Buffer__Tariff_No__CaptionLbl: Label 'Tariff No.';
        NoOfRecordsCaptionLbl: Label 'Prog.';
        Intra___form_Buffer__Transaction_Type__Control1130018CaptionLbl: Label 'Transaction Type';
        Intra___form_Buffer__Source_Currency_Amount_CaptionLbl: Label 'Source Currency Amount';
        RoundAmount_Control1130016CaptionLbl: Label 'Amount';
        Intra___form_Buffer__VAT_Registration_No___Control1130015CaptionLbl: Label 'VAT Registration No.';
        Intra___form_Buffer__Country_code__Control1130014CaptionLbl: Label 'Country/Region code';
        NoOfRecords_Control1130013CaptionLbl: Label 'Prog.';
        Intra___form_Buffer__Tariff_No___Control1130019CaptionLbl: Label 'Tariff No.';
        TotRoundAmountCaptionLbl: Label 'Total Amount';

    local procedure GetPaymentMethod()
    begin
        if not (PaymentMethod.Code = "Intrastat Jnl. Line"."Payment Method") then begin
            Clear(PaymentMethod);
            if "Intrastat Jnl. Line"."Payment Method" <> '' then
                PaymentMethod.Get("Intrastat Jnl. Line"."Payment Method");
        end;
    end;
}

