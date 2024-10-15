report 31068 "VIES Declaration - Test"
{
    DefaultLayout = RDLC;
    RDLCLayout = './VIESDeclarationTest.rdlc';
    Caption = 'VIES Declaration - Test';

    dataset
    {
        dataitem("VIES Declaration Header"; "VIES Declaration Header")
        {
            DataItemTableView = SORTING("No.");
            RequestFilterFields = "No.";
            column(FORMAT_TODAY_0_4_; Format(Today, 0, 4))
            {
            }
            column(USERID; UserId)
            {
            }
            column(CurrReport_PAGENO; CurrReport.PageNo)
            {
            }
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName)
            {
            }
            column(VIES_Declaration_Header__No__; "No.")
            {
            }
            column(VIES_Declaration_Header__VAT_Registration_No__; "VAT Registration No.")
            {
            }
            column(VIES_Declaration_Header__Trade_Type_; "Trade Type")
            {
            }
            column(VIES_Declaration_Header__Period_No__; "Period No.")
            {
            }
            column(VIES_Declaration_Header_Year; Year)
            {
            }
            column(VIES_Declaration_Header__Start_Date_; "Start Date")
            {
            }
            column(VIES_Declaration_Header__End_Date_; "End Date")
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
            column(VIES_Declaration_Header__Tax_Office_Number_; "Tax Office Number")
            {
            }
            column(VIES_Declaration_Header__Declaration_Type_; "Declaration Type")
            {
            }
            column(VIES_Declaration_Header__Corrected_Declaration_No__; "Corrected Declaration No.")
            {
            }
            column(VIES_Declaration_Header__Document_Date_; "Document Date")
            {
            }
            column(VIES_Declaration_Header__Authorized_Employee_No__; "Authorized Employee No.")
            {
            }
            column(VIES_Declaration_Header__Filled_by_Employee_No__; "Filled by Employee No.")
            {
            }
            column(VIES_Declaration_Header__Purchase_Amount__LCY__; "Purchase Amount (LCY)")
            {
            }
            column(VIES_Declaration_Header__Sales_Amount__LCY__; "Sales Amount (LCY)")
            {
            }
            column(VIES_Declaration_Header__Amount__LCY__; "Amount (LCY)")
            {
            }
            column(VIES_Declaration_Header__Number_of_Supplies_; "Number of Supplies")
            {
            }
            column(VIES_Declaration_Header__EU_Goods_Services_; "EU Goods/Services")
            {
            }
            column(VIES_Declaration_Header__Declaration_Period_; "Declaration Period")
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(VIES_Declaration___TestCaption; VIES_Declaration___TestCaptionLbl)
            {
            }
            column(VIES_Declaration_Header__No__Caption; FieldCaption("No."))
            {
            }
            column(VIES_Declaration_Header__VAT_Registration_No__Caption; FieldCaption("VAT Registration No."))
            {
            }
            column(VIES_Declaration_Header__Trade_Type_Caption; FieldCaption("Trade Type"))
            {
            }
            column(VIES_Declaration_Header__Period_No__Caption; FieldCaption("Period No."))
            {
            }
            column(VIES_Declaration_Header_YearCaption; FieldCaption(Year))
            {
            }
            column(VIES_Declaration_Header__Start_Date_Caption; FieldCaption("Start Date"))
            {
            }
            column(VIES_Declaration_Header__End_Date_Caption; FieldCaption("End Date"))
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
            column(VIES_Declaration_Header_CountyCaption; FieldCaption(County))
            {
            }
            column(VIES_Declaration_Header__Municipality_No__Caption; FieldCaption("Municipality No."))
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
            column(VIES_Declaration_Header__Tax_Office_Number_Caption; FieldCaption("Tax Office Number"))
            {
            }
            column(VIES_Declaration_Header__Declaration_Type_Caption; FieldCaption("Declaration Type"))
            {
            }
            column(VIES_Declaration_Header__Corrected_Declaration_No__Caption; FieldCaption("Corrected Declaration No."))
            {
            }
            column(VIES_Declaration_Header__Document_Date_Caption; FieldCaption("Document Date"))
            {
            }
            column(VIES_Declaration_Header__Authorized_Employee_No__Caption; FieldCaption("Authorized Employee No."))
            {
            }
            column(VIES_Declaration_Header__Filled_by_Employee_No__Caption; FieldCaption("Filled by Employee No."))
            {
            }
            column(VIES_Declaration_Header__Purchase_Amount__LCY__Caption; FieldCaption("Purchase Amount (LCY)"))
            {
            }
            column(VIES_Declaration_Header__Sales_Amount__LCY__Caption; FieldCaption("Sales Amount (LCY)"))
            {
            }
            column(VIES_Declaration_Header__Amount__LCY__Caption; FieldCaption("Amount (LCY)"))
            {
            }
            column(VIES_Declaration_Header__Number_of_Supplies_Caption; FieldCaption("Number of Supplies"))
            {
            }
            column(VIES_Declaration_Header__EU_Goods_Services_Caption; FieldCaption("EU Goods/Services"))
            {
            }
            column(VIES_Declaration_Header__Declaration_Period_Caption; FieldCaption("Declaration Period"))
            {
            }
            dataitem(HeaderErrorCounter; "Integer")
            {
                DataItemTableView = SORTING(Number);
                column(ErrorText_Number_; ErrorText[Number])
                {
                }
                column(ErrorText_Number_Caption; ErrorText_Number_CaptionLbl)
                {
                }
                column(HeaderErrorCounter_Number; Number)
                {
                }

                trigger OnPostDataItem()
                begin
                    ErrorCounter := 0;
                end;

                trigger OnPreDataItem()
                begin
                    SetRange(Number, 1, ErrorCounter);
                end;
            }
            dataitem("VIES Declaration Line"; "VIES Declaration Line")
            {
                DataItemLink = "VIES Declaration No." = FIELD("No.");
                DataItemLinkReference = "VIES Declaration Header";
                DataItemTableView = SORTING("VIES Declaration No.", "Line No.");
                column(VIES_Declaration_Line__Trade_Type_; "Trade Type")
                {
                }
                column(VIES_Declaration_Line__Line_Type_; "Line Type")
                {
                }
                column(VIES_Declaration_Line__Country_Region_Code_; "Country/Region Code")
                {
                }
                column(VIES_Declaration_Line__VAT_Registration_No__; "VAT Registration No.")
                {
                }
                column(VIES_Declaration_Line__Registration_No__; "Registration No.")
                {
                }
                column(VIES_Declaration_Line__EU_3_Party_Trade_; Format("EU 3-Party Trade"))
                {
                }
                column(VIES_Declaration_Line__EU_3_Party_Intermediate_Role_; Format("EU 3-Party Intermediate Role"))
                {
                }
                column(VIES_Declaration_Line__Trade_Role_Type_; "Trade Role Type")
                {
                }
                column(VIES_Declaration_Line__Amount__LCY__; "Amount (LCY)")
                {
                }
                column(VIES_Declaration_Line__Corrected_Reg__No__; Format("Corrected Reg. No."))
                {
                }
                column(VIES_Declaration_Line__Corrected_Amount_; Format("Corrected Amount"))
                {
                }
                column(VIES_Declaration_Line__Trade_Type_Caption; FieldCaption("Trade Type"))
                {
                }
                column(VIES_Declaration_Line__Line_Type_Caption; FieldCaption("Line Type"))
                {
                }
                column(VIES_Declaration_Line__Country_Region_Code_Caption; FieldCaption("Country/Region Code"))
                {
                }
                column(VIES_Declaration_Line__VAT_Registration_No__Caption; FieldCaption("VAT Registration No."))
                {
                }
                column(VIES_Declaration_Line__Registration_No__Caption; FieldCaption("Registration No."))
                {
                }
                column(VIES_Declaration_Line__EU_3_Party_Trade_Caption; FieldCaption("EU 3-Party Trade"))
                {
                }
                column(VIES_Declaration_Line__EU_3_Party_Intermediate_Role_Caption; FieldCaption("EU 3-Party Intermediate Role"))
                {
                }
                column(VIES_Declaration_Line__Trade_Role_Type_Caption; FieldCaption("Trade Role Type"))
                {
                }
                column(VIES_Declaration_Line__Amount__LCY__Caption; FieldCaption("Amount (LCY)"))
                {
                }
                column(VIES_Declaration_Line__Corrected_Reg__No__Caption; FieldCaption("Corrected Reg. No."))
                {
                }
                column(VIES_Declaration_Line__Corrected_Amount_Caption; FieldCaption("Corrected Amount"))
                {
                }
                column(VIES_Declaration_Line_VIES_Declaration_No_; "VIES Declaration No.")
                {
                }
                column(VIES_Declaration_Line_Line_No_; "Line No.")
                {
                }
                dataitem(LineErrorCounter; "Integer")
                {
                    DataItemTableView = SORTING(Number);
                    column(ErrorText_Number__Control1470075; ErrorText[Number])
                    {
                    }
                    column(ErrorText_Number__Control1470075Caption; ErrorText_Number__Control1470075CaptionLbl)
                    {
                    }
                    column(LineErrorCounter_Number; Number)
                    {
                    }

                    trigger OnPostDataItem()
                    begin
                        ErrorCounter := 0;
                    end;

                    trigger OnPreDataItem()
                    begin
                        SetRange(Number, 1, ErrorCounter);
                    end;
                }

                trigger OnAfterGetRecord()
                begin
                    if "Country/Region Code" = '' then
                        AddError(StrSubstNo(Text006, FieldCaption("Country/Region Code")));
                    if "VAT Registration No." = '' then
                        AddError(StrSubstNo(Text006, FieldCaption("VAT Registration No.")));
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if "VAT Registration No." = '' then
                    AddError(StrSubstNo(Text006, FieldCaption("VAT Registration No.")));
                if "Start Date" = 0D then
                    AddError(StrSubstNo(Text006, FieldCaption("Start Date")));
                if "End Date" = 0D then
                    AddError(StrSubstNo(Text006, FieldCaption("End Date")));
                if Name = '' then
                    AddError(StrSubstNo(Text006, FieldCaption(Name)));
                if "Country/Region Name" = '' then
                    AddError(StrSubstNo(Text006, FieldCaption("Country/Region Name")));
                if "Municipality No." = '' then
                    AddError(StrSubstNo(Text006, FieldCaption("Municipality No.")));
                if Street = '' then
                    AddError(StrSubstNo(Text006, FieldCaption(Street)));
                if "House No." = '' then
                    AddError(StrSubstNo(Text006, FieldCaption("House No.")));
                if "Apartment No." = '' then
                    AddError(StrSubstNo(Text006, FieldCaption("Apartment No.")));
                if City = '' then
                    AddError(StrSubstNo(Text006, FieldCaption(City)));
                if "Post Code" = '' then
                    AddError(StrSubstNo(Text006, FieldCaption("Post Code")));
                if "Tax Office Number" = '' then
                    AddError(StrSubstNo(Text006, FieldCaption("Tax Office Number")));
                if "Document Date" = 0D then
                    AddError(StrSubstNo(Text006, FieldCaption("Document Date")));
                if "Filled by Employee No." = '' then
                    AddError(StrSubstNo(Text006, FieldCaption("Filled by Employee No.")));
                if "Authorized Employee No." = '' then
                    AddError(StrSubstNo(Text006, FieldCaption("Authorized Employee No.")));
                if "Declaration Type" = "Declaration Type"::Corrective then
                    if "Corrected Declaration No." = '' then
                        AddError(StrSubstNo(Text006, FieldCaption("Corrected Declaration No.")));
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
        ErrorText: array[99] of Text[250];
        ErrorCounter: Integer;
        Text006: Label '%1 must be specified.';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        VIES_Declaration___TestCaptionLbl: Label 'VIES Declaration - Test';
        Post_Code_CityCaptionLbl: Label 'Post Code/City';
        ErrorText_Number_CaptionLbl: Label 'Warning!';
        ErrorText_Number__Control1470075CaptionLbl: Label 'Warning!';

    local procedure AddError(Text: Text[250])
    begin
        ErrorCounter := ErrorCounter + 1;
        ErrorText[ErrorCounter] := Text;
    end;
}

