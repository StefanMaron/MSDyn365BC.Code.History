report 31060 "VIES Declaration"
{
    DefaultLayout = RDLC;
    RDLCLayout = './VIESDeclaration.rdlc';
    Caption = 'VIES Declaration';

    dataset
    {
        dataitem("VIES Declaration Header"; "VIES Declaration Header")
        {
            DataItemTableView = SORTING("No.");
            RequestFilterFields = "No.";
            column(STRSUBSTNO_Text000_CurrReport_PAGENO_; StrSubstNo(Text000, CurrReport.PageNo))
            {
            }
            column(CompanyInfo__VAT_Registration_No__; CompanyInfo."VAT Registration No.")
            {
            }
            column(CompanyInfo__Registration_No__; CompanyInfo."Registration No.")
            {
            }
            column(CompanyInfo__Tax_Registration_No__; CompanyInfo."Tax Registration No.")
            {
            }
            column(FORMAT__VIES_Declaration_Header___Declaration_Period__; Format("Declaration Period"))
            {
            }
            column(VIES_Declaration_Header__VIES_Declaration_Header__Year; Year)
            {
            }
            column(VIES_Declaration_Header__VIES_Declaration_Header___Period_No__; "Period No.")
            {
            }
            column(VIES_Declaration_Header_Name; Name)
            {
            }
            column(VIES_Declaration_Header__Name_2_; "Name 2")
            {
            }
            column(VIES_Declaration_Header__Country_Region_Name_; "Country/Region Name")
            {
            }
            column(VIES_Declaration_Header_County; County)
            {
            }
            column(VIES_Declaration_Header__Municipality_No__; "Municipality No.")
            {
            }
            column(VIES_Declaration_Header_Street; Street)
            {
            }
            column(VIES_Declaration_Header__House_No__; "House No.")
            {
            }
            column(VIES_Declaration_Header__Apartment_No__; "Apartment No.")
            {
            }
            column(VIES_Declaration_Header_City; City)
            {
            }
            column(VIES_Declaration_Header__Post_Code_; "Post Code")
            {
            }
            column(VIES_DECLARATIONCaption; VIES_DECLARATIONCaptionLbl)
            {
            }
            column(TotalValueItemSaleSuppliesCaption; TotalValueItemSaleSuppliesCaptionLbl)
            {
            }
            column(TotalValueEU3rdPartyItemSaleCaption; TotalValueEU3rdPartyItemSaleCaptionLbl)
            {
            }
            column(TotalValueofItemPurchSuppliesCaption; TotalValueofItemPurchSuppliesCaptionLbl)
            {
            }
            column(TotalValueServiceSalSuppliesCaption; TotalValueServiceSalSuppliesCaptionLbl)
            {
            }
            column(VIES_Declaration_Line__VAT_Registration_No__Caption; VIES_Declaration_Line__VAT_Registration_No__CaptionLbl)
            {
            }
            column(VIES_Declaration_Line__VIES_Declaration_Line___Country_Region_Code_Caption; VIES_Declaration_Line__VIES_Declaration_Line___Country_Region_Code_CaptionLbl)
            {
            }
            column(CompanyInfo__VAT_Registration_No__Caption; CompanyInfo__VAT_Registration_No__CaptionLbl)
            {
            }
            column(CompanyInfo__Registration_No__Caption; CompanyInfo__Registration_No__CaptionLbl)
            {
            }
            column(CompanyInfo__Tax_Registration_No__Caption; CompanyInfo__Tax_Registration_No__CaptionLbl)
            {
            }
            column(Registration_Nos__Caption; Registration_Nos__CaptionLbl)
            {
            }
            column(Declaration_Period_Caption; Declaration_Period_CaptionLbl)
            {
            }
            column(VIES_Declaration_Header__VIES_Declaration_Header__YearCaption; VIES_Declaration_Header__VIES_Declaration_Header__YearCaptionLbl)
            {
            }
            column(VIES_Declaration_Header_NameCaption; FieldCaption(Name))
            {
            }
            column(VIES_Declaration_Header__Name_2_Caption; FieldCaption("Name 2"))
            {
            }
            column(VIES_Declaration_Header__Country_Region_Name_Caption; FieldCaption("Country/Region Name"))
            {
            }
            column(VIES_Declaration_Header__Municipality_No__Caption; FieldCaption("Municipality No."))
            {
            }
            column(VIES_Declaration_Header_CountyCaption; FieldCaption(County))
            {
            }
            column(VIES_Declaration_Header_StreetCaption; FieldCaption(Street))
            {
            }
            column(VIES_Declaration_Header__House_No__Caption; FieldCaption("House No."))
            {
            }
            column(VIES_Declaration_Header__Apartment_No__Caption; FieldCaption("Apartment No."))
            {
            }
            column(Post_Code_CityCaption; Post_Code_CityCaptionLbl)
            {
            }
            column(Name_and_Address_Caption; Name_and_Address_CaptionLbl)
            {
            }
            column(VIES_Declaration_Header_No_; "No.")
            {
            }
            dataitem("VIES Declaration Line"; "VIES Declaration Line")
            {
                DataItemLink = "VIES Declaration No." = FIELD("No.");
                DataItemTableView = SORTING("VAT Registration No.");
                column(TotalValueEU3rdPartyItemSale; TotalValueEU3rdPartyItemSale)
                {
                    AutoFormatType = 1;
                }
                column(TotalValueServiceSalSupplies; TotalValueServiceSalSupplies)
                {
                }
                column(TotalValueofItemPurchSupplies; TotalValueofItemPurchSupplies)
                {
                    AutoFormatType = 1;
                }
                column(TotalValueItemSaleSupplies; TotalValueItemSaleSupplies)
                {
                }
                column(VIES_Declaration_Line__VAT_Registration_No__; "VAT Registration No.")
                {
                }
                column(VIES_Declaration_Line__VIES_Declaration_Line___Country_Region_Code_; "Country/Region Code")
                {
                }
                column(VIES_Declaration_Line_VIES_Declaration_No_; "VIES Declaration No.")
                {
                }
                column(VIES_Declaration_Line_Line_No_; "Line No.")
                {
                }

                trigger OnAfterGetRecord()
                begin
                    case "Trade Type" of
                        "Trade Type"::Purchase:
                            TotalValueofItemPurchSupplies := "Amount (LCY)";
                        "Trade Type"::Sale:
                            if "EU Service" then begin
                                TotalValueServiceSalSupplies := "Amount (LCY)";
                            end else begin
                                if "EU 3-Party Trade" then
                                    TotalValueEU3rdPartyItemSale := "Amount (LCY)"
                                else
                                    TotalValueItemSaleSupplies := "Amount (LCY)";
                            end;
                    end;
                end;

                trigger OnPreDataItem()
                begin
                    Clear(TotalValueItemSaleSupplies);
                    Clear(TotalValueEU3rdPartyItemSale);
                    Clear(TotalValueServiceSalSupplies);
                    Clear(TotalValueofItemPurchSupplies);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                TestField("Authorized Employee No.");
                CompanyOfficials.Get("Authorized Employee No.");
                FormatAddr.FormatAddr(ViesDeclAddr, CopyStr(Name, 1, 90), "Name 2", '', Street, CopyStr(DelChr("House No.", '<>', ' ') +
                    DelChr("Apartment No.", '<>', ' '), 1, 50), City, "Post Code", County, CompanyInfo."Country/Region Code");
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

    trigger OnPreReport()
    begin
        CompanyInfo.Get;
    end;

    var
        Text000: Label 'Page %1';
        VIES_DECLARATIONCaptionLbl: Label 'VIES DECLARATION';
        TotalValueItemSaleSuppliesCaptionLbl: Label 'Value of Item Sale';
        TotalValueEU3rdPartyItemSaleCaptionLbl: Label 'Value of EU 3-Party Item Sale';
        TotalValueofItemPurchSuppliesCaptionLbl: Label 'Value of Item Purchase';
        TotalValueServiceSalSuppliesCaptionLbl: Label 'Value of Service Sale';
        VIES_Declaration_Line__VAT_Registration_No__CaptionLbl: Label 'VAT Registration No.';
        VIES_Declaration_Line__VIES_Declaration_Line___Country_Region_Code_CaptionLbl: Label 'Country Code';
        CompanyInfo__VAT_Registration_No__CaptionLbl: Label 'VAT Reg. No.';
        CompanyInfo__Registration_No__CaptionLbl: Label 'Reg. No.';
        CompanyInfo__Tax_Registration_No__CaptionLbl: Label 'Tax Registration No.';
        Registration_Nos__CaptionLbl: Label 'Registration Nos.:';
        Declaration_Period_CaptionLbl: Label 'Declaration Period:';
        VIES_Declaration_Header__VIES_Declaration_Header__YearCaptionLbl: Label 'Year';
        Post_Code_CityCaptionLbl: Label 'Post Code/City';
        Name_and_Address_CaptionLbl: Label 'Name and Address:';
        CompanyInfo: Record "Company Information";
        CompanyOfficials: Record "Company Officials";
        FormatAddr: Codeunit "Format Address";
        ViesDeclAddr: array[8] of Text[100];
        TotalValueServiceSalSupplies: Decimal;
        TotalValueItemSaleSupplies: Decimal;
        TotalValueofItemPurchSupplies: Decimal;
        TotalValueEU3rdPartyItemSale: Decimal;
}

