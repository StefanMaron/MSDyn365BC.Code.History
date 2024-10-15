report 12160 "Intrastat - Monthly Report"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Intrastat/IntrastatMonthlyReport.rdlc';
    Caption = 'Intrastat - Monthly Report';

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
            column(Intrastat_Jnl__Batch_Type; Type)
            {
            }
            dataitem("Intrastat Jnl. Line"; "Intrastat Jnl. Line")
            {
                DataItemLink = "Journal Template Name" = FIELD("Journal Template Name"), "Journal Batch Name" = FIELD(Name), Type = FIELD(Type);
                DataItemTableView = SORTING(Type, "Country/Region Code", "Partner VAT ID", "Transaction Type", "Tariff No.", "Group Code", "Transport Method", "Transaction Specification", "Country/Region of Origin Code", Area, "Corrective entry") ORDER(Ascending);
                RequestFilterFields = "Journal Template Name", "Journal Batch Name";
                column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
                {
                }
                column(STRSUBSTNO_Text002__Intrastat_Jnl__Batch___Statistics_Period__; StrSubstNo(Text002, "Intrastat Jnl. Batch"."Statistics Period"))
                {
                }
                column(COMPANYNAME; COMPANYPROPERTY.DisplayName)
                {
                }
                column(USERID; UserId)
                {
                }
                column(Intrastat_Jnl__Line__Intrastat_Jnl__Line__Type; Format("Intrastat Jnl. Line".Type))
                {
                }
                column(CompanyInfo__VAT_Registration_No__; CompanyInfo."VAT Registration No.")
                {
                }
                column(DocType; DocType)
                {
                }
                column(Sales; Sales)
                {
                }
                column(Intrastat_Jnl__Batch___Corrective_Entry_; "Intrastat Jnl. Batch"."Corrective Entry")
                {
                }
                column(Intrastat_Jnl__Batch___EU_Service_; "Intrastat Jnl. Batch"."EU Service")
                {
                }
                column(NoOfRecords_Control1130008; NoOfRecords)
                {
                }
                column(Intrastat_Jnl__Line__Country_Region_Code_; "Country/Region Code")
                {
                }
                column(Intrastat_Jnl__Line__VAT_Registration_No__; "Partner VAT ID")
                {
                }
                column(RoundAmount_Control1130016; RoundAmount)
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
                column(Intrastat_Jnl__Line__Country_Region_Code__Control1130119; "Country/Region Code")
                {
                }
                column(NoOfRecords_Control1130010; NoOfRecords)
                {
                }
                column(Intrastat_Jnl__Line__Country_Region_Code__Control1130121; "Country/Region Code")
                {
                }
                column(Intrastat_Jnl__Line__VAT_Registration_No___Control1130123; "Partner VAT ID")
                {
                }
                column(RoundAmount_Control1130125; RoundAmount)
                {
                    DecimalPlaces = 0 : 0;
                }
                column(Intrastat_Jnl__Line__Source_Currency_Amount_; "Source Currency Amount")
                {
                }
                column(Intrastat_Jnl__Line__Document_No___Control1130129; "Document No.")
                {
                }
                column(Intrastat_Jnl__Line_Date_Control1130131; Format(Date))
                {
                }
                column(Intrastat_Jnl__Line__Service_Tariff_No___Control1130133; "Service Tariff No.")
                {
                }
                column(Intrastat_Jnl__Line__Transport_Method__Control1130135; "Transport Method")
                {
                }
                column(Intrastat_Jnl__Line__Payment_Method__Control1130137; PaymentMethod."Intrastat Payment Method")
                {
                }
                column(Intrastat_Jnl__Line__Country_Region_of_Payment_Code_; "Country/Region of Payment Code")
                {
                }
                column(NoOfRecords_Control1130141; NoOfRecords)
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
                column(Intrastat_Jnl__Line__Country_Region_Code__Control1130153; "Country/Region Code")
                {
                }
                column(Intrastat_Jnl__Line__VAT_Registration_No___Control1130155; "Partner VAT ID")
                {
                }
                column(RoundAmount_Control1130157; RoundAmount)
                {
                    DecimalPlaces = 0 : 0;
                }
                column(Intrastat_Jnl__Line__Document_No___Control1130159; "Document No.")
                {
                }
                column(Intrastat_Jnl__Line_Date_Control1130161; Format(Date))
                {
                }
                column(Intrastat_Jnl__Line__Service_Tariff_No___Control1130163; "Service Tariff No.")
                {
                }
                column(Intrastat_Jnl__Line__Transport_Method__Control1130165; "Transport Method")
                {
                }
                column(Intrastat_Jnl__Line__Payment_Method__Control1130167; PaymentMethod."Intrastat Payment Method")
                {
                }
                column(Intrastat_Jnl__Line__Country_Region_Code__Control1130169; "Country/Region Code")
                {
                }
                column(NoOfRecords_Control1130171; NoOfRecords)
                {
                }
                column(Intrastat_Jnl__Line__Custom_Office_No___Control1130173; "Custom Office No.")
                {
                }
                column(Intrastat_Jnl__Line__Reference_Period__Control1130175; "Reference Period")
                {
                }
                column(Intrastat_Jnl__Line__Corrected_Intrastat_Report_No___Control1130177; "Corrected Intrastat Report No.")
                {
                }
                column(Intrastat_Jnl__Line__Corrected_Document_No___Control1130179; "Corrected Document No.")
                {
                }
                column(Intrastat_Jnl__Line__Country_Region_Code__Control1130181; "Country/Region Code")
                {
                }
                column(Intrastat_Jnl__Line__VAT_Registration_No___Control1130183; "Partner VAT ID")
                {
                }
                column(RoundAmount_Control1130185; RoundAmount)
                {
                    DecimalPlaces = 0 : 0;
                }
                column(Intrastat_Jnl__Line__Source_Currency_Amount__Control1130187; "Source Currency Amount")
                {
                }
                column(Intrastat_Jnl__Line__Document_No___Control1130189; "Document No.")
                {
                }
                column(Intrastat_Jnl__Line_Date_Control1130191; Format(Date))
                {
                }
                column(Intrastat_Jnl__Line__Service_Tariff_No___Control1130193; "Service Tariff No.")
                {
                }
                column(Intrastat_Jnl__Line__Transport_Method__Control1130195; "Transport Method")
                {
                }
                column(Intrastat_Jnl__Line__Payment_Method__Control1130197; PaymentMethod."Intrastat Payment Method")
                {
                }
                column(Intrastat_Jnl__Line__Country_Region_of_Payment_Code__Control1130199; "Country/Region of Payment Code")
                {
                }
                column(RoundAmount_Control1130145; RoundAmount)
                {
                    DecimalPlaces = 0 : 0;
                }
                column(RoundAmount_Control1130206; RoundAmount)
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
                column(Intrastat_Jnl__Line_Type; Type)
                {
                }
                column(Intrastat___Monthly_ReportCaption; Intrastat___Monthly_ReportCaptionLbl)
                {
                }
                column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
                {
                }
                column(CompanyInfo__VAT_Registration_No__Caption; CompanyInfo__VAT_Registration_No__CaptionLbl)
                {
                }
                column(NoOfRecords_Control1130008Caption; NoOfRecords_Control1130008CaptionLbl)
                {
                }
                column(Intrastat_Jnl__Line__Country_Region_Code_Caption; FieldCaption("Country/Region Code"))
                {
                }
#if CLEAN18
                column(Intrastat_Jnl__Line__VAT_Registration_No__Caption; Intra___form_Buffer__VAT_Registration_No__CaptionLbl)
                {
                }
#else
                column(Intrastat_Jnl__Line__VAT_Registration_No__Caption; FieldCaption("VAT Registration No."))
                {
                }
#endif
                column(RoundAmount_Control1130016Caption; RoundAmount_Control1130016CaptionLbl)
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
                column(Intrastat_Jnl__Line__Country_Region_Code__Control1130119Caption; Intrastat_Jnl__Line__Country_Region_Code__Control1130119CaptionLbl)
                {
                }
                column(NoOfRecords_Control1130010Caption; NoOfRecords_Control1130010CaptionLbl)
                {
                }
                column(Intrastat_Jnl__Line__Country_Region_Code__Control1130121Caption; FieldCaption("Country/Region Code"))
                {
                }
#if CLEAN18
                column(Intrastat_Jnl__Line__VAT_Registration_No___Control1130123Caption; Intra___form_Buffer__VAT_Registration_No__CaptionLbl)
                {
                }
#else
                column(Intrastat_Jnl__Line__VAT_Registration_No___Control1130123Caption; FieldCaption("VAT Registration No."))
                {
                }
#endif
                column(RoundAmount_Control1130125Caption; RoundAmount_Control1130125CaptionLbl)
                {
                }
                column(Intrastat_Jnl__Line__Source_Currency_Amount_Caption; Intrastat_Jnl__Line__Source_Currency_Amount_CaptionLbl)
                {
                }
                column(Intrastat_Jnl__Line__Document_No___Control1130129Caption; FieldCaption("Document No."))
                {
                }
                column(Intrastat_Jnl__Line_Date_Control1130131Caption; Intrastat_Jnl__Line_Date_Control1130131CaptionLbl)
                {
                }
                column(Intrastat_Jnl__Line__Service_Tariff_No___Control1130133Caption; Intrastat_Jnl__Line__Service_Tariff_No___Control1130133CaptionLbl)
                {
                }
                column(Intrastat_Jnl__Line__Transport_Method__Control1130135Caption; Intrastat_Jnl__Line__Transport_Method__Control1130135CaptionLbl)
                {
                }
                column(Intrastat_Jnl__Line__Payment_Method__Control1130137Caption; Intrastat_Jnl__Line__Payment_Method__Control1130137CaptionLbl)
                {
                }
                column(Intrastat_Jnl__Line__Country_Region_of_Payment_Code_Caption; Intrastat_Jnl__Line__Country_Region_of_Payment_Code_CaptionLbl)
                {
                }
                column(NoOfRecords_Control1130141Caption; NoOfRecords_Control1130141CaptionLbl)
                {
                }
                column(Intrastat_Jnl__Line__Custom_Office_No__Caption; FieldCaption("Custom Office No."))
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
                column(Intrastat_Jnl__Line__Country_Region_Code__Control1130153Caption; FieldCaption("Country/Region Code"))
                {
                }
#if CLEAN18
                column(Intrastat_Jnl__Line__VAT_Registration_No___Control1130155Caption; Intra___form_Buffer__VAT_Registration_No__CaptionLbl)
                {
                }
#else
                column(Intrastat_Jnl__Line__VAT_Registration_No___Control1130155Caption; FieldCaption("VAT Registration No."))
                {
                }
#endif
                column(RoundAmount_Control1130157Caption; RoundAmount_Control1130157CaptionLbl)
                {
                }
                column(Intrastat_Jnl__Line__Document_No___Control1130159Caption; FieldCaption("Document No."))
                {
                }
                column(Intrastat_Jnl__Line_Date_Control1130161Caption; Intrastat_Jnl__Line_Date_Control1130161CaptionLbl)
                {
                }
                column(Intrastat_Jnl__Line__Service_Tariff_No___Control1130163Caption; Intrastat_Jnl__Line__Service_Tariff_No___Control1130163CaptionLbl)
                {
                }
                column(Intrastat_Jnl__Line__Transport_Method__Control1130165Caption; Intrastat_Jnl__Line__Transport_Method__Control1130165CaptionLbl)
                {
                }
                column(Intrastat_Jnl__Line__Payment_Method__Control1130167Caption; Intrastat_Jnl__Line__Payment_Method__Control1130167CaptionLbl)
                {
                }
                column(Intrastat_Jnl__Line__Country_Region_Code__Control1130169Caption; Intrastat_Jnl__Line__Country_Region_Code__Control1130169CaptionLbl)
                {
                }
                column(NoOfRecords_Control1130171Caption; NoOfRecords_Control1130171CaptionLbl)
                {
                }
                column(Intrastat_Jnl__Line__Custom_Office_No___Control1130173Caption; Intrastat_Jnl__Line__Custom_Office_No___Control1130173CaptionLbl)
                {
                }
                column(Intrastat_Jnl__Line__Reference_Period__Control1130175Caption; Intrastat_Jnl__Line__Reference_Period__Control1130175CaptionLbl)
                {
                }
                column(Intrastat_Jnl__Line__Corrected_Intrastat_Report_No___Control1130177Caption; Intrastat_Jnl__Line__Corrected_Intrastat_Report_No___Control1130177CaptionLbl)
                {
                }
                column(Intrastat_Jnl__Line__Corrected_Document_No___Control1130179Caption; FieldCaption("Corrected Document No."))
                {
                }
                column(Intrastat_Jnl__Line__Country_Region_Code__Control1130181Caption; FieldCaption("Country/Region Code"))
                {
                }
#if CLEAN18
                column(Intrastat_Jnl__Line__VAT_Registration_No___Control1130183Caption; Intra___form_Buffer__VAT_Registration_No__CaptionLbl)
                {
                }
#else
                column(Intrastat_Jnl__Line__VAT_Registration_No___Control1130183Caption; FieldCaption("VAT Registration No."))
                {
                }
#endif
                column(RoundAmount_Control1130185Caption; RoundAmount_Control1130185CaptionLbl)
                {
                }
                column(Intrastat_Jnl__Line__Source_Currency_Amount__Control1130187Caption; Intrastat_Jnl__Line__Source_Currency_Amount__Control1130187CaptionLbl)
                {
                }
                column(Intrastat_Jnl__Line__Document_No___Control1130189Caption; FieldCaption("Document No."))
                {
                }
                column(Intrastat_Jnl__Line_Date_Control1130191Caption; Intrastat_Jnl__Line_Date_Control1130191CaptionLbl)
                {
                }
                column(Intrastat_Jnl__Line__Service_Tariff_No___Control1130193Caption; Intrastat_Jnl__Line__Service_Tariff_No___Control1130193CaptionLbl)
                {
                }
                column(Intrastat_Jnl__Line__Transport_Method__Control1130195Caption; Intrastat_Jnl__Line__Transport_Method__Control1130195CaptionLbl)
                {
                }
                column(Intrastat_Jnl__Line__Payment_Method__Control1130197Caption; Intrastat_Jnl__Line__Payment_Method__Control1130197CaptionLbl)
                {
                }
                column(Intrastat_Jnl__Line__Country_Region_of_Payment_Code__Control1130199Caption; Intrastat_Jnl__Line__Country_Region_of_Payment_Code__Control1130199CaptionLbl)
                {
                }
                column(RoundAmount_Control1130145Caption; RoundAmount_Control1130145CaptionLbl)
                {
                }
                column(RoundAmount_Control1130206Caption; RoundAmount_Control1130206CaptionLbl)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    Country.Get("Country/Region Code");

                    if "Intrastat Jnl. Batch"."EU Service" then begin
                        TestField("Partner VAT ID");
                        TestField("Country/Region Code");
                        TestField("Service Tariff No.");
                        NoOfRecords := NoOfRecords + 1;
                        RoundAmount := Round(Amount, 1);
                        GetPaymentMethod;
                    end else
                        if not "Intrastat Jnl. Batch"."Corrective Entry" then begin
                            if ("Tariff No." = '') and
                               ("Country/Region Code" = '') and
                               ("Transaction Type" = '') and
                               ("Transport Method" = '') and
                               ("Total Weight" = 0)
                            then
                                CurrReport.Skip();

                            TestField("Partner VAT ID");
                            TestField("Transaction Type");
                            TestField("Tariff No.");
                            TestField("Country/Region Code");
                            TestField("Transaction Type");
                            TestField("Total Weight");

                            if "Supplementary Units" then
                                TestField(Quantity);
                            if "Intrastat Jnl. Batch".Type = "Intrastat Jnl. Batch".Type::Purchases then begin
                                TestField("Country/Region of Origin Code");
                                CountryOriginCode := "Country/Region of Origin Code";
                                Sales := false;
                            end else begin
                                CountryOriginCode := '';
                                Sales := true;
                            end;
                            if "Intrastat Jnl. Line"."Supplementary Units" = false then
                                SupplUnits := 0
                            else
                                SupplUnits := "Intrastat Jnl. Line".Quantity;

                            "Intra - form Buffer".Reset();
                            if "Intra - form Buffer".Get("Partner VAT ID", "Intrastat Jnl. Line"."Transaction Type",
                                 "Intrastat Jnl. Line"."Tariff No.", "Intrastat Jnl. Line"."Group Code", "Intrastat Jnl. Line"."Transport Method",
                                 "Intrastat Jnl. Line"."Transaction Specification", CountryOriginCode, "Intrastat Jnl. Line".Area,
                                 "Intrastat Jnl. Line"."Corrective entry")
                            then begin
                                "Intra - form Buffer".Amount := Round("Intra - form Buffer".Amount, 1) + Round("Intrastat Jnl. Line".Amount, 1);
                                "Intra - form Buffer"."Source Currency Amount" := "Intra - form Buffer"."Source Currency Amount" +
                                  "Intrastat Jnl. Line"."Source Currency Amount";
                                "Intra - form Buffer"."Total Weight" := "Intra - form Buffer"."Total Weight" + "Intrastat Jnl. Line"."Total Weight";
                                "Intra - form Buffer"."Statistical Value" := Round("Intra - form Buffer"."Statistical Value", 1) +
                                  Round("Intrastat Jnl. Line"."Statistical Value", 1);
                                "Intra - form Buffer".Quantity := "Intra - form Buffer".Quantity + SupplUnits;
                                "Intra - form Buffer".Modify();
                            end else begin
                                "Intra - form Buffer".TransferFields("Intrastat Jnl. Line");
                                "Intra - form Buffer"."VAT Registration No." :=
                                  CopyStr("Partner VAT ID", 1, MaxStrLen("Intra - form Buffer"."VAT Registration No."));
                                "Intra - form Buffer"."Country/Region of Origin Code" := CountryOriginCode;
                                "Intra - form Buffer".Quantity := SupplUnits;
                                "Intra - form Buffer"."No." := 0;
                                "Intra - form Buffer"."User ID" := UserId;
                                "Intra - form Buffer".Insert();
                            end;
                        end else begin          // Corrective Entry
                            if "Reference Period" >= "Intrastat Jnl. Batch"."Statistics Period" then
                                Error(Text1130002, FieldCaption("Statistics Period"));

                            TestField("Country/Region Code");
                            TestField("Partner VAT ID");
                            TestField("Transaction Type");
                            TestField("Tariff No.");
                            TestField("Reference Period");
                            TestField("Group Code");
                            TestField(Area);
                            TestField("Total Weight");
                            TestField("Transport Method");
                            TestField("Transaction Specification");
                            LineNo := LineNo + 1;

                            "Intra - form Buffer".TransferFields("Intrastat Jnl. Line");
                            "Intra - form Buffer"."Country/Region of Origin Code" := CountryOriginCode;
                            "Intra - form Buffer".Quantity := SupplUnits;
                            "Intra - form Buffer"."User ID" := UserId;
                            "Intra - form Buffer"."No." := LineNo;
                            "Intra - form Buffer".Insert();
                        end
                        ;
                end;

                trigger OnPreDataItem()
                begin
                    LineNo := 0;
                    Clear(RoundAmount);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if "Corrective Entry" then
                    DocType := Text1130000
                else
                    DocType := Text1130001;
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
            column(Intrastat_Jnl__Batch___Corrective_Entry_Old; "Intrastat Jnl. Batch"."Corrective Entry")
            {
            }
            column(Sales_Old; Sales)
            {
            }
            column(Intra___form_Buffer__Country_code_; "Country/Region Code")
            {
            }
            column(Intra___form_Buffer__Transaction_Type_; "Transaction Type")
            {
            }
            column(RoundAmount; RoundAmount)
            {
                AutoFormatType = 0;
                DecimalPlaces = 0 : 0;
            }
            column(Intra___form_Buffer__VAT_Registration_No__; "VAT Registration No.")
            {
            }
            column(Intra___form_Buffer__Source_Currency_Amount_; "Source Currency Amount")
            {
                AutoFormatType = 0;
                DecimalPlaces = 0 : 0;
            }
            column(Intra___form_Buffer__Tariff_No__; "Tariff No.")
            {
            }
            column(Intra___form_Buffer_Quantity; Quantity)
            {
                AutoFormatType = 0;
                DecimalPlaces = 0 : 0;
            }
            column(RoundStatValue; RoundStatValue)
            {
                AutoFormatType = 0;
                DecimalPlaces = 0 : 0;
            }
            column(Intra___form_Buffer__Group_Code_; "Group Code")
            {
            }
            column(Intra___form_Buffer__Transport_Method_; "Transport Method")
            {
            }
            column(Intra___form_Buffer__Country_of_Origin_Code_; "Country/Region of Origin Code")
            {
            }
            column(Intra___form_Buffer_Area; Area)
            {
            }
            column(Intra___form_Buffer__Transaction_Specification_; "Transaction Specification")
            {
            }
            column(NoOfRecords; NoOfRecords)
            {
            }
            column(Month; Month)
            {
            }
            column(Year; Year)
            {
            }
            column(Intra___form_Buffer__Total_Weight_; "Total Weight")
            {
                DecimalPlaces = 0 : 0;
            }
            column(Intra___form_Buffer__Tariff_No___Control1130076; "Tariff No.")
            {
            }
            column(Intra___form_Buffer__Country_code__Control1130071; "Country/Region Code")
            {
            }
            column(RoundAmount_Control1130073; RoundAmount)
            {
                AutoFormatType = 0;
                DecimalPlaces = 0 : 0;
            }
            column(Intra___form_Buffer__VAT_Registration_No___Control1130072; "VAT Registration No.")
            {
            }
            column(Intra___form_Buffer__Total_Weight__Control1130077; "Total Weight")
            {
                DecimalPlaces = 0 : 0;
            }
            column(Intra___form_Buffer_Quantity_Control1130078; Quantity)
            {
                AutoFormatType = 0;
                DecimalPlaces = 0 : 0;
            }
            column(RoundStatValue_Control1130079; RoundStatValue)
            {
                AutoFormatType = 0;
                DecimalPlaces = 0 : 0;
            }
            column(Intra___form_Buffer__Group_Code__Control1130080; "Group Code")
            {
            }
            column(Intra___form_Buffer__Transport_Method__Control1130081; "Transport Method")
            {
            }
            column(Intra___form_Buffer__Transaction_Specification__Control1130082; "Transaction Specification")
            {
            }
            column(Intra___form_Buffer_Area_Control1130084; Area)
            {
            }
            column(NoOfRecords_Control1130070; NoOfRecords)
            {
            }
            column(Intra___form_Buffer__Source_Currency_Amount__Control1130074; "Source Currency Amount")
            {
                AutoFormatType = 0;
                DecimalPlaces = 0 : 0;
            }
            column(Intra___form_Buffer__Transaction_Type__Control1130075; "Transaction Type")
            {
            }
            column(Intra___form_Buffer__Country_of_Origin_Code__Control1130083; "Country/Region of Origin Code")
            {
            }
            column(Intra___form_Buffer__Country_code__Control1130099; "Country/Region Code")
            {
            }
            column(Intra___form_Buffer__VAT_Registration_No___Control1130100; "VAT Registration No.")
            {
            }
            column(Intra___form_Buffer__Tariff_No___Control1130103; "Tariff No.")
            {
            }
            column(Intra___form_Buffer__Transaction_Type__Control1130102; "Transaction Type")
            {
            }
            column(RoundAmount_Control1130101; RoundAmount)
            {
                AutoFormatType = 0;
                DecimalPlaces = 0 : 0;
            }
            column(RoundTotalWeight; RoundTotalWeight)
            {
                DecimalPlaces = 0 : 0;
            }
            column(RoundQty; RoundQty)
            {
                DecimalPlaces = 0 : 0;
            }
            column(Intra___form_Buffer__Group_Code__Control1130107; "Group Code")
            {
            }
            column(RoundStatValue_Control1130106; RoundStatValue)
            {
                AutoFormatType = 0;
                DecimalPlaces = 0 : 0;
            }
            column(Intra___form_Buffer__Transport_Method__Control1130108; "Transport Method")
            {
            }
            column(Intra___form_Buffer__Transaction_Specification__Control1130109; "Transaction Specification")
            {
            }
            column(Intra___form_Buffer_Area_Control1130110; Area)
            {
            }
            column(NoOfRecords_Control1130098; NoOfRecords)
            {
            }
            column(TotRoundAmount; TotRoundAmount)
            {
                AutoFormatType = 0;
                DecimalPlaces = 0 : 0;
            }
            column(TotRoundAmount_Control1130005; TotRoundAmount)
            {
                AutoFormatType = 0;
                DecimalPlaces = 0 : 0;
            }
            column(Intra___form_Buffer_Corrective_entry; "Corrective entry")
            {
            }
            column(Intra___form_Buffer_No_; "No.")
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
            column(Intra___form_Buffer__VAT_Registration_No__Caption; Intra___form_Buffer__VAT_Registration_No__CaptionLbl)
            {
            }
            column(Intra___form_Buffer__Source_Currency_Amount_Caption; Intra___form_Buffer__Source_Currency_Amount_CaptionLbl)
            {
            }
            column(Intra___form_Buffer__Tariff_No__Caption; Intra___form_Buffer__Tariff_No__CaptionLbl)
            {
            }
            column(Intra___form_Buffer__Total_Weight_Caption; Intra___form_Buffer__Total_Weight_CaptionLbl)
            {
            }
            column(Intra___form_Buffer_QuantityCaption; Intra___form_Buffer_QuantityCaptionLbl)
            {
            }
            column(Intra___form_Buffer__Group_Code_Caption; Intra___form_Buffer__Group_Code_CaptionLbl)
            {
            }
            column(Intra___form_Buffer__Transport_Method_Caption; Intra___form_Buffer__Transport_Method_CaptionLbl)
            {
            }
            column(Intra___form_Buffer__Country_of_Origin_Code_Caption; Intra___form_Buffer__Country_of_Origin_Code_CaptionLbl)
            {
            }
            column(Intra___form_Buffer_AreaCaption; Intra___form_Buffer_AreaCaptionLbl)
            {
            }
            column(Intra___form_Buffer__Transaction_Specification_Caption; Intra___form_Buffer__Transaction_Specification_CaptionLbl)
            {
            }
            column(MonthCaption; MonthCaptionLbl)
            {
            }
            column(YearCaption; YearCaptionLbl)
            {
            }
            column(RoundStatValueCaption; RoundStatValueCaptionLbl)
            {
            }
            column(NoOfRecordsCaption; NoOfRecordsCaptionLbl)
            {
            }
            column(Intra___form_Buffer__Tariff_No___Control1130076Caption; Intra___form_Buffer__Tariff_No___Control1130076CaptionLbl)
            {
            }
            column(Intra___form_Buffer__Country_code__Control1130071Caption; Intra___form_Buffer__Country_code__Control1130071CaptionLbl)
            {
            }
            column(RoundAmount_Control1130073Caption; RoundAmount_Control1130073CaptionLbl)
            {
            }
            column(Intra___form_Buffer__VAT_Registration_No___Control1130072Caption; Intra___form_Buffer__VAT_Registration_No___Control1130072CaptionLbl)
            {
            }
            column(Intra___form_Buffer__Total_Weight__Control1130077Caption; Intra___form_Buffer__Total_Weight__Control1130077CaptionLbl)
            {
            }
            column(Intra___form_Buffer_Quantity_Control1130078Caption; Intra___form_Buffer_Quantity_Control1130078CaptionLbl)
            {
            }
            column(RoundStatValue_Control1130079Caption; RoundStatValue_Control1130079CaptionLbl)
            {
            }
            column(Intra___form_Buffer__Group_Code__Control1130080Caption; Intra___form_Buffer__Group_Code__Control1130080CaptionLbl)
            {
            }
            column(Intra___form_Buffer__Transport_Method__Control1130081Caption; Intra___form_Buffer__Transport_Method__Control1130081CaptionLbl)
            {
            }
            column(Intra___form_Buffer__Transaction_Specification__Control1130082Caption; FieldCaption("Transaction Specification"))
            {
            }
            column(Intra___form_Buffer_Area_Control1130084Caption; Intra___form_Buffer_Area_Control1130084CaptionLbl)
            {
            }
            column(NoOfRecords_Control1130070Caption; NoOfRecords_Control1130070CaptionLbl)
            {
            }
            column(Intra___form_Buffer__Source_Currency_Amount__Control1130074Caption; Intra___form_Buffer__Source_Currency_Amount__Control1130074CaptionLbl)
            {
            }
            column(Intra___form_Buffer__Transaction_Type__Control1130075Caption; Intra___form_Buffer__Transaction_Type__Control1130075CaptionLbl)
            {
            }
            column(Intra___form_Buffer__Country_of_Origin_Code__Control1130083Caption; Intra___form_Buffer__Country_of_Origin_Code__Control1130083CaptionLbl)
            {
            }
            column(Intra___form_Buffer__Country_code__Control1130099Caption; Intra___form_Buffer__Country_code__Control1130099CaptionLbl)
            {
            }
            column(Intra___form_Buffer__VAT_Registration_No___Control1130100Caption; Intra___form_Buffer__VAT_Registration_No___Control1130100CaptionLbl)
            {
            }
            column(RoundAmount_Control1130101Caption; RoundAmount_Control1130101CaptionLbl)
            {
            }
            column(Intra___form_Buffer__Transaction_Type__Control1130102Caption; Intra___form_Buffer__Transaction_Type__Control1130102CaptionLbl)
            {
            }
            column(Intra___form_Buffer__Tariff_No___Control1130103Caption; Intra___form_Buffer__Tariff_No___Control1130103CaptionLbl)
            {
            }
            column(RoundTotalWeightCaption; RoundTotalWeightCaptionLbl)
            {
            }
            column(RoundQtyCaption; RoundQtyCaptionLbl)
            {
            }
            column(Intra___form_Buffer__Group_Code__Control1130107Caption; Intra___form_Buffer__Group_Code__Control1130107CaptionLbl)
            {
            }
            column(RoundStatValue_Control1130106Caption; RoundStatValue_Control1130106CaptionLbl)
            {
            }
            column(Intra___form_Buffer__Transport_Method__Control1130108Caption; Intra___form_Buffer__Transport_Method__Control1130108CaptionLbl)
            {
            }
            column(Intra___form_Buffer__Transaction_Specification__Control1130109Caption; Intra___form_Buffer__Transaction_Specification__Control1130109CaptionLbl)
            {
            }
            column(Intra___form_Buffer_Area_Control1130110Caption; Intra___form_Buffer_Area_Control1130110CaptionLbl)
            {
            }
            column(NoOfRecords_Control1130098Caption; NoOfRecords_Control1130098CaptionLbl)
            {
            }
            column(TotRoundAmountCaption; TotRoundAmountCaptionLbl)
            {
            }
            column(TotRoundAmount_Control1130005Caption; TotRoundAmount_Control1130005CaptionLbl)
            {
            }

            trigger OnAfterGetRecord()
            begin
                NoOfRecords := NoOfRecords + 1;

                RoundTotalWeight := Round("Total Weight", 1);
                RoundQty := Round(Quantity, 1);
                RoundCurrAmount := Round("Source Currency Amount", 1);
                RoundStatValue := Round("Statistical Value", 1);
                RoundAmount := Round(Amount, 1);
                TotRoundAmount := TotRoundAmount + RoundAmount;
                Month := CopyStr("Reference Period", 3, 2);
                Year := CopyStr("Reference Period", 1, 2);
            end;

            trigger OnPreDataItem()
            begin
                if "Intrastat Jnl. Batch"."EU Service" then
                    CurrReport.Break();

                NoOfRecords := 0;
                TotRoundAmount := 0;
                if "Intrastat Jnl. Batch"."Corrective Entry" then
                    SetCurrentKey("Reference Period")
                else
                    SetCurrentKey("VAT Registration No.");
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
        CompanyInfo.Get();
        CompanyInfo."VAT Registration No." := ConvertStr(CompanyInfo."VAT Registration No.", Text001, '    ');

        "Intra - form Buffer".Reset();
        "Intra - form Buffer".SetFilter("User ID", UserId);
        "Intra - form Buffer".DeleteAll();
    end;

    var
        Text001: Label 'WwWw';
        Text002: Label 'Statistics Period: %1';
        Text003: Label 'All amounts are in %1';
        CompanyInfo: Record "Company Information";
        Country: Record "Country/Region";
        PaymentMethod: Record "Payment Method";
        NoOfRecords: Integer;
        Text1130000: Label 'Adjustment Declaration';
        Text1130001: Label 'New Declaration';
        Text1130002: Label 'Reference Period must be previous later %1';
        RoundTotalWeight: Decimal;
        RoundQty: Decimal;
        RoundStatValue: Decimal;
        RoundAmount: Decimal;
        TotRoundAmount: Decimal;
        RoundCurrAmount: Decimal;
        SupplUnits: Decimal;
        BatchNameFilter: Text;
        Month: Code[10];
        Year: Code[10];
        CountryOriginCode: Code[10];
        DocType: Text[30];
        LineNo: Integer;
        Sales: Boolean;
        Intrastat___Monthly_ReportCaptionLbl: Label 'Intrastat - Monthly Report';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        CompanyInfo__VAT_Registration_No__CaptionLbl: Label 'VAT Reg. No.';
        NoOfRecords_Control1130008CaptionLbl: Label 'Prog.';
        RoundAmount_Control1130016CaptionLbl: Label 'Amount';
        Intrastat_Jnl__Line_DateCaptionLbl: Label 'Date';
        Intrastat_Jnl__Line__Service_Tariff_No__CaptionLbl: Label 'Service Tariff Code';
        Intrastat_Jnl__Line__Transport_Method_CaptionLbl: Label 'Transport Method Code';
        Intrastat_Jnl__Line__Payment_Method_CaptionLbl: Label 'Payment Method Code';
        Intrastat_Jnl__Line__Country_Region_Code__Control1130119CaptionLbl: Label 'Payment Country/Region Code';
        NoOfRecords_Control1130010CaptionLbl: Label 'Prog.';
        RoundAmount_Control1130125CaptionLbl: Label 'Amount';
        Intrastat_Jnl__Line__Source_Currency_Amount_CaptionLbl: Label 'Amount in Src. Currency';
        Intrastat_Jnl__Line_Date_Control1130131CaptionLbl: Label 'Date';
        Intrastat_Jnl__Line__Service_Tariff_No___Control1130133CaptionLbl: Label 'Service Tariff Code';
        Intrastat_Jnl__Line__Transport_Method__Control1130135CaptionLbl: Label 'Transport Method Code';
        Intrastat_Jnl__Line__Payment_Method__Control1130137CaptionLbl: Label 'Payment Method Code';
        Intrastat_Jnl__Line__Country_Region_of_Payment_Code_CaptionLbl: Label 'Payment Country/Region Code';
        NoOfRecords_Control1130141CaptionLbl: Label 'Prog.';
        Intrastat_Jnl__Line__Reference_Period_CaptionLbl: Label 'Year';
        Intrastat_Jnl__Line__Corrected_Intrastat_Report_No__CaptionLbl: Label 'Corrected Intrastat Report';
        RoundAmount_Control1130157CaptionLbl: Label 'Amount';
        Intrastat_Jnl__Line_Date_Control1130161CaptionLbl: Label 'Date';
        Intrastat_Jnl__Line__Service_Tariff_No___Control1130163CaptionLbl: Label 'Service Tariff Code';
        Intrastat_Jnl__Line__Transport_Method__Control1130165CaptionLbl: Label 'Transport Method Code';
        Intrastat_Jnl__Line__Payment_Method__Control1130167CaptionLbl: Label 'Payment Method Code';
        Intrastat_Jnl__Line__Country_Region_Code__Control1130169CaptionLbl: Label 'Payment Country/Region Code';
        NoOfRecords_Control1130171CaptionLbl: Label 'Prog.';
        Intrastat_Jnl__Line__Custom_Office_No___Control1130173CaptionLbl: Label 'Customs Office No.';
        Intrastat_Jnl__Line__Reference_Period__Control1130175CaptionLbl: Label 'Year';
        Intrastat_Jnl__Line__Corrected_Intrastat_Report_No___Control1130177CaptionLbl: Label 'Corrected Intrastat Report';
        RoundAmount_Control1130185CaptionLbl: Label 'Amount';
        Intrastat_Jnl__Line__Source_Currency_Amount__Control1130187CaptionLbl: Label 'Amount in Src. Currency';
        Intrastat_Jnl__Line_Date_Control1130191CaptionLbl: Label 'Date';
        Intrastat_Jnl__Line__Service_Tariff_No___Control1130193CaptionLbl: Label 'Service Tariff Code';
        Intrastat_Jnl__Line__Transport_Method__Control1130195CaptionLbl: Label 'Transport Method Code';
        Intrastat_Jnl__Line__Payment_Method__Control1130197CaptionLbl: Label 'Payment Method Code';
        Intrastat_Jnl__Line__Country_Region_of_Payment_Code__Control1130199CaptionLbl: Label 'Payment Country/Region Code';
        RoundAmount_Control1130145CaptionLbl: Label 'Total Amount';
        RoundAmount_Control1130206CaptionLbl: Label 'Total Amount';
        Intra___form_Buffer__Country_code_CaptionLbl: Label 'Country/Region code';
        RoundAmountCaptionLbl: Label 'Amount';
        Intra___form_Buffer__Transaction_Type_CaptionLbl: Label 'Transaction Type';
        Intra___form_Buffer__VAT_Registration_No__CaptionLbl: Label 'VAT Registration No.';
        Intra___form_Buffer__Source_Currency_Amount_CaptionLbl: Label 'Source Currency Amount';
        Intra___form_Buffer__Tariff_No__CaptionLbl: Label 'Tariff No.';
        Intra___form_Buffer__Total_Weight_CaptionLbl: Label 'Net Weight';
        Intra___form_Buffer_QuantityCaptionLbl: Label 'Suppl. Units';
        Intra___form_Buffer__Group_Code_CaptionLbl: Label 'Group Code';
        Intra___form_Buffer__Transport_Method_CaptionLbl: Label 'Transport Method';
        Intra___form_Buffer__Country_of_Origin_Code_CaptionLbl: Label 'Country/Region of Origin Code';
        Intra___form_Buffer_AreaCaptionLbl: Label 'Area';
        Intra___form_Buffer__Transaction_Specification_CaptionLbl: Label 'Transaction Specification';
        MonthCaptionLbl: Label 'Month';
        YearCaptionLbl: Label 'Year';
        RoundStatValueCaptionLbl: Label 'Statistical Value';
        NoOfRecordsCaptionLbl: Label 'Prog.';
        Intra___form_Buffer__Tariff_No___Control1130076CaptionLbl: Label 'Tariff No.';
        Intra___form_Buffer__Country_code__Control1130071CaptionLbl: Label 'Country/Region code';
        RoundAmount_Control1130073CaptionLbl: Label 'Amount';
        Intra___form_Buffer__VAT_Registration_No___Control1130072CaptionLbl: Label 'VAT Registration No.';
        Intra___form_Buffer__Total_Weight__Control1130077CaptionLbl: Label 'Net Weight';
        Intra___form_Buffer_Quantity_Control1130078CaptionLbl: Label 'Suppl. Units';
        RoundStatValue_Control1130079CaptionLbl: Label 'Statistical Value';
        Intra___form_Buffer__Group_Code__Control1130080CaptionLbl: Label 'Group Code';
        Intra___form_Buffer__Transport_Method__Control1130081CaptionLbl: Label 'Transport Method';
        Intra___form_Buffer_Area_Control1130084CaptionLbl: Label 'Area';
        NoOfRecords_Control1130070CaptionLbl: Label 'Prog.';
        Intra___form_Buffer__Source_Currency_Amount__Control1130074CaptionLbl: Label 'Source Currency Amount';
        Intra___form_Buffer__Transaction_Type__Control1130075CaptionLbl: Label 'Transaction Type';
        Intra___form_Buffer__Country_of_Origin_Code__Control1130083CaptionLbl: Label 'Country/Region of Origin Code';
        Intra___form_Buffer__Country_code__Control1130099CaptionLbl: Label 'Country/Region code';
        Intra___form_Buffer__VAT_Registration_No___Control1130100CaptionLbl: Label 'VAT Registration No.';
        RoundAmount_Control1130101CaptionLbl: Label 'Amount';
        Intra___form_Buffer__Transaction_Type__Control1130102CaptionLbl: Label 'Transaction Type';
        Intra___form_Buffer__Tariff_No___Control1130103CaptionLbl: Label 'Tariff No.';
        RoundTotalWeightCaptionLbl: Label 'Net Weight';
        RoundQtyCaptionLbl: Label 'Suppl. Units';
        Intra___form_Buffer__Group_Code__Control1130107CaptionLbl: Label 'Group Code';
        RoundStatValue_Control1130106CaptionLbl: Label 'Statistical Value';
        Intra___form_Buffer__Transport_Method__Control1130108CaptionLbl: Label 'Transport Method';
        Intra___form_Buffer__Transaction_Specification__Control1130109CaptionLbl: Label 'Transaction Specification';
        Intra___form_Buffer_Area_Control1130110CaptionLbl: Label 'Area';
        NoOfRecords_Control1130098CaptionLbl: Label 'Prog.';
        TotRoundAmountCaptionLbl: Label 'Total Amount';
        TotRoundAmount_Control1130005CaptionLbl: Label 'Total Amount';

    local procedure GetPaymentMethod()
    begin
        if not (PaymentMethod.Code = "Intrastat Jnl. Line"."Payment Method") then begin
            Clear(PaymentMethod);
            if "Intrastat Jnl. Line"."Payment Method" <> '' then
                PaymentMethod.Get("Intrastat Jnl. Line"."Payment Method");
        end;
    end;
}

