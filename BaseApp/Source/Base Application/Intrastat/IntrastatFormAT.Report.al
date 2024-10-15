report 11104 "Intrastat - Form AT"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Intrastat/IntrastatFormAT.rdlc';
    Caption = 'Intrastat - Form AT';

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
            dataitem(Init; "Intrastat Jnl. Line")
            {
                DataItemLink = "Journal Template Name" = FIELD("Journal Template Name"), "Journal Batch Name" = FIELD(Name);
                DataItemTableView = SORTING("Journal Template Name", "Journal Batch Name", Type, "Country/Region Code", "Tariff No.", "Transaction Type", "Transport Method", Area, "Transaction Specification", "Country/Region of Origin Code") WHERE("Tariff No." = FILTER(<> ''));

                trigger OnAfterGetRecord()
                begin
                    AdditionalField :=
                      Format("Country/Region Code", 5) + Format("Tariff No.", 10) +
                      Format("Transaction Type", 10) + Format("Transport Method", 10) +
                      Format("Transaction Specification", 10) + Format("Country/Region of Origin Code", 5);

                    if (TempType <> Type) or (StrLen(TempAdditionalField) = 0) then begin
                        TempType := Type;
                        TempAdditionalField := AdditionalField;
                        IntraReferenceNo := CopyStr(IntraReferenceNo, 1, 4) + '001001';
                    end else
                        if TempAdditionalField <> AdditionalField then begin
                            TempAdditionalField := AdditionalField;
                            if CopyStr(IntraReferenceNo, 8, 3) = '999' then
                                IntraReferenceNo := IncStr(CopyStr(IntraReferenceNo, 1, 7)) + '001'
                            else
                                IntraReferenceNo := IncStr(IntraReferenceNo);
                        end;

                    "Internal Ref. No." := IntraReferenceNo;
                    Modify;
                end;
            }
            dataitem("Intrastat Jnl. Line"; "Intrastat Jnl. Line")
            {
                DataItemLink = "Journal Template Name" = FIELD("Journal Template Name"), "Journal Batch Name" = FIELD(Name);
                DataItemTableView = SORTING(Type, "Internal Ref. No.") WHERE("Tariff No." = FILTER(<> ''));
                RequestFilterFields = Type;
                column(COPYSTR__Intrastat_Jnl__Batch___Statistics_Period__1_2_; CopyStr("Intrastat Jnl. Batch"."Statistics Period", 1, 2))
                {
                }
                column(Companyinfo_Name; Companyinfo.Name)
                {
                }
                column(COPYSTR__Intrastat_Jnl__Batch___Statistics_Period__3_2_; CopyStr("Intrastat Jnl. Batch"."Statistics Period", 3, 2))
                {
                }
                column(Companyinfo__Name_2_; Companyinfo."Name 2")
                {
                }
                column(Companyinfo_Address; Companyinfo.Address)
                {
                }
                column(Companyinfo_City; Companyinfo.City)
                {
                }
                column(Companyinfo__VAT_Registration_No__; Companyinfo."VAT Registration No.")
                {
                }
                column(Intrastat_Jnl__Line__Intrastat_Jnl__Line___Internal_Ref__No__; "Intrastat Jnl. Line"."Internal Ref. No.")
                {
                }
                column(Intrastat_Jnl__Line__Tariff_No__; "Tariff No.")
                {
                }
                column(Intrastat_Jnl__Line__Item_Description_; "Item Description")
                {
                }
                column(Country__Intrastat_Code_; Country."Intrastat Code")
                {
                }
                column(Intrastat_Jnl__Line__Transaction_Type_; "Transaction Type")
                {
                }
                column(Intrastat_Jnl__Line__Transport_Method_; "Transport Method")
                {
                }
                column(Intrastat_Jnl__Line__Transaction_Specification_; "Transaction Specification")
                {
                }
                column(Intrastat_Jnl__Line__Total_Weight_; "Total Weight")
                {
                }
                column(Intrastat_Jnl__Line_Quantity; Quantity)
                {
                }
                column(Intrastat_Jnl__Line_Amount; Amount)
                {
                }
                column(Intrastat_Jnl__Line__Statistical_Value_; "Statistical Value")
                {
                }
                column(RecCount; RecCount)
                {
                }
                column(CountryOfOriginCode; CountryOfOriginCode)
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

                trigger OnAfterGetRecord()
                begin
                    if ("Tariff No." = '') and
                       ("Country/Region Code" = '') and
                       ("Transaction Type" = '') and
                       ("Transport Method" = '') and
                       ("Total Weight" = 0)
                    then
                        CurrReport.Skip();

                    if IntrastatSetup."Use Advanced Checklist" then
                        IntraJnlManagement.ValidateReportWithAdvancedChecklist("Intrastat Jnl. Line", Report::"Intrastat - Form AT", true)
                    else begin
                        TestField("Tariff No.");
                        TestField("Country/Region Code");
                        TestField("Transaction Type");
                        TestField("Total Weight");
                        if Companyinfo."Check Transport Method" then
                            TestField("Transport Method");
                        if Companyinfo."Check Transaction Specific." then
                            TestField("Transaction Specification");
                        if "Supplementary Units" then
                            TestField(Quantity)
                    end;

                    if Companyinfo."Check Transaction Specific." then
                        if StrLen("Transaction Specification") <> 5 then
                            Error(Text002, "Transaction Specification");
                    if not "Supplementary Units" then
                        Quantity := 0;

                    if Amount <> 0 then
                        Amount := Round(Amount);
                    if "Statistical Value" <> 0 then
                        "Statistical Value" := Round("Statistical Value");
                    if "Net Weight" <> 0 then
                        "Net Weight" := Round("Net Weight", 1, '<');

                    if CurrentNoSaved <> "Intrastat Jnl. Line"."Line No." then begin
                        RecCount := RecCount + 1;
                        Country.Get("Country/Region Code");
                        if Type = Type::Receipt then begin
                            if "Country/Region of Origin Code" <> '' then begin
                                CountryOfOrigin.Get("Country/Region of Origin Code");
                                CountryOfOriginCode := CountryOfOrigin."EU Country/Region Code";
                            end else
                                CountryOfOriginCode := "Intrastat Jnl. Line"."Country/Region Code";
                        end else
                            CountryOfOriginCode := '';
                        if not "Supplementary Units" then
                            Quantity := 0;

                        CurrentNoSaved := "Intrastat Jnl. Line"."Line No.";
                    end;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                IntraReferenceNo := "Statistics Period" + '000000';
                IntraJnlManagement.ChecklistClearBatchErrors("Intrastat Jnl. Batch");
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

    trigger OnPreReport()
    begin
        if not ("Intrastat Jnl. Line".GetRangeMin(Type) = "Intrastat Jnl. Line".GetRangeMax(Type)) then
            "Intrastat Jnl. Line".FieldError(Type, Text000);

        Companyinfo.Get();
        Companyinfo."VAT Registration No." := ConvertStr(Companyinfo."VAT Registration No.", Text001, '    ');
        if IntrastatSetup.Get() then;
    end;

    var
        Text000: Label 'must be either Receipt or Shipment';
        Text001: Label 'WwWw';
        Text002: Label 'Transaction Specification %1 must have 5 digits.';
        Companyinfo: Record "Company Information";
        Country: Record "Country/Region";
        CountryOfOrigin: Record "Country/Region";
        IntrastatSetup: Record "Intrastat Setup";
        IntraJnlManagement: Codeunit IntraJnlManagement;
        CountryOfOriginCode: Code[2];
        RecCount: Integer;
        CurrentNoSaved: Integer;
        AdditionalField: Code[50];
        TempAdditionalField: Code[50];
        TempType: Integer;
        IntraReferenceNo: Text[10];
}

