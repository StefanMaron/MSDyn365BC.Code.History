#if not CLEAN22
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Intrastat;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Registration;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using System.Environment;

report 501 "Intrastat - Form"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Inventory/Intrastat/IntrastatForm.rdlc';
    ApplicationArea = BasicEU;
    Caption = 'Intrastat - Form';
    UsageCategory = ReportsAndAnalysis;
    ObsoleteState = Pending;
    ObsoleteTag = '22.0';
    ObsoleteReason = 'Intrastat related functionalities are moved to Intrastat extensions.';

    dataset
    {
        dataitem("Intrastat Jnl. Batch"; "Intrastat Jnl. Batch")
        {
            DataItemTableView = sorting("Journal Template Name", Name);
            PrintOnlyIfDetail = true;
            RequestFilterFields = "Journal Template Name", Name;
            column(Company_Name; Company.Name)
            {
            }
            column(Company_Address; Company.Address)
            {
            }
            column(Company__Post_Code_______Company_City; Company."Post Code" + '  ' + Company.City)
            {
            }
            column(Company__Ship_to_Contact_; Company."Ship-to Contact")
            {
            }
            column(Company__Phone_No__; Company."Phone No.")
            {
            }
            column(Company__Fax_No__; Company."Fax No.")
            {
            }
            column(Vvatno; Vvatno)
            {
            }
            column(Vthird_1_; Vthird[1])
            {
            }
            column(Vthird_6_; Vthird[6])
            {
            }
            column(Vthird_2_; Vthird[2])
            {
            }
            column(Vthird_3_; Vthird[3])
            {
            }
            column(Vthird_4_; Vthird[4])
            {
            }
            column(Vthird_5_; Vthird[5])
            {
            }
            column(Vthird_7_; Vthird[7])
            {
            }
            column(Text2; Text2)
            {
            }
            column(VMonth; VMonth)
            {
            }
            column(Text1; Text1)
            {
            }
            column(Pages; Pages)
            {
            }
            column(VMessage; VMessage)
            {
            }
            column(Company__Intrastat_Establishment_No__; Company."Intrastat Establishment No.")
            {
            }
            column(VYear; VYear)
            {
            }
            column(Navision__________ApplicationSystemConstants_ApplicationVersion_________Text11312; 'Navision' + ' ' + ApplicationSystemConstants.ApplicationVersion() + ' ' + Text11312)
            {
            }
            column(V1Caption; V1CaptionLbl)
            {
            }
            column(V2Caption; V2CaptionLbl)
            {
            }
            column(V3Caption; V3CaptionLbl)
            {
            }
            column(V4Caption; V4CaptionLbl)
            {
            }
            column(XCaption; XCaptionLbl)
            {
            }
            column(TELCaption; TELCaptionLbl)
            {
            }
            column(TELCaption_Control1010077; TELCaption_Control1010077Lbl)
            {
            }
            column(FAXCaption; FAXCaptionLbl)
            {
            }
            column(FAXCaption_Control1010079; FAXCaption_Control1010079Lbl)
            {
            }
            column(V14Caption; V14CaptionLbl)
            {
            }
            column(V12Caption; V12CaptionLbl)
            {
            }
            column(V13Caption; V13CaptionLbl)
            {
            }
            column(V11Caption; V11CaptionLbl)
            {
            }
            column(V10Caption; V10CaptionLbl)
            {
            }
            column(V9Caption; V9CaptionLbl)
            {
            }
            column(V8Caption; V8CaptionLbl)
            {
            }
            column(V7Caption; V7CaptionLbl)
            {
            }
            column(V6Caption; V6CaptionLbl)
            {
            }
            column(V5Caption; V5CaptionLbl)
            {
            }
            column(BNBB__de_Berlaimont_14__1000_BRUCaption; BNBB__de_Berlaimont_14__1000_BRUCaptionLbl)
            {
            }
            column(Intrastat_Jnl__Batch_Journal_Template_Name; "Journal Template Name")
            {
            }
            column(Intrastat_Jnl__Batch_Name; Name)
            {
            }
            dataitem("Intrastat Jnl. Line"; "Intrastat Jnl. Line")
            {
                DataItemLink = "Journal Template Name" = field("Journal Template Name"), "Journal Batch Name" = field(Name);
                DataItemTableView = sorting(Type, "Country/Region Code", "Tariff No.", "Transaction Type", "Transport Method", "Transaction Specification", Area);
                RequestFilterFields = Type;
                column(Company_Name_Control1010009; Company.Name)
                {
                }
                column(Company_Address_Control1010010; Company.Address)
                {
                }
                column(Company__Post_Code_______Company_City_Control1010011; Company."Post Code" + '  ' + Company.City)
                {
                }
                column(Company__Ship_to_Contact__Control1010012; Company."Ship-to Contact")
                {
                }
                column(Company__Phone_No___Control1010037; Company."Phone No.")
                {
                }
                column(Company__Fax_No___Control1010038; Company."Fax No.")
                {
                }
                column(Vvatno_Control1010041; Vvatno)
                {
                }
                column(Vthird_1__Control1010039; Vthird[1])
                {
                }
                column(Vthird_6__Control1010044; Vthird[6])
                {
                }
                column(Vthird_2__Control1010045; Vthird[2])
                {
                }
                column(Vthird_3__Control1010046; Vthird[3])
                {
                }
                column(Vthird_4__Control1010047; Vthird[4])
                {
                }
                column(Vthird_5__Control1010048; Vthird[5])
                {
                }
                column(Vthird_7__Control1010049; Vthird[7])
                {
                }
                column(Text2_Control1010004; Text2)
                {
                }
                column(VMonth_Control1010005; VMonth)
                {
                }
                column(Text1_Control1010006; Text1)
                {
                }
                column(Pages_Control1010003; Pages)
                {
                }
                column(VMessage_Control1010013; VMessage)
                {
                }
                column(Company__Intrastat_Establishment_No___Control1010015; Company."Intrastat Establishment No.")
                {
                }
                column(VYear_Control1010017; VYear)
                {
                }
                column(Navision__________ApplicationSystemConstants_ApplicationVersion_________Text11312_Control1010000; 'Navision' + ' ' + ApplicationSystemConstants.ApplicationVersion() + ' ' + Text11312)
                {
                }
                column(TWeight; TWeight)
                {
                }
                column(TValue; TValue)
                {
                }
                column(TUnits; TUnits)
                {
                }
                column(Intrastat_Jnl__Line__Tariff_No__; "Tariff No.")
                {
                }
                column(Intrastat_Jnl__Line__Transaction_Type_; "Transaction Type")
                {
                }
                column(TTransportMethod; TTransportMethod)
                {
                }
                column(Country__Intrastat_Code_; Country."Intrastat Code")
                {
                }
                column(TIncoTerm; TIncoTerm)
                {
                }
                column(TArea; TArea)
                {
                }
                column(Index; Index)
                {
                }
                column(Type; Type)
                {
                }
                column(Text_Index; Text_Index)
                {
                }
                column(TValue_Total; TValue_Total)
                {
                }
                column(TWeight_Total; TWeight_Total)
                {
                }
                column(Nihil; Nihil)
                {
                }
                column(NewPageNumber; NewPageNumber)
                {
                }
                column(V1Caption_Control1010008; V1Caption_Control1010008Lbl)
                {
                }
                column(V2Caption_Control1010040; V2Caption_Control1010040Lbl)
                {
                }
                column(V3Caption_Control1010042; V3Caption_Control1010042Lbl)
                {
                }
                column(V4Caption_Control1010043; V4Caption_Control1010043Lbl)
                {
                }
                column(XCaption_Control1010007; XCaption_Control1010007Lbl)
                {
                }
                column(TELCaption_Control1010033; TELCaption_Control1010033Lbl)
                {
                }
                column(TELCaption_Control1010065; TELCaption_Control1010065Lbl)
                {
                }
                column(FAXCaption_Control1010068; FAXCaption_Control1010068Lbl)
                {
                }
                column(FAXCaption_Control1010069; FAXCaption_Control1010069Lbl)
                {
                }
                column(V14Caption_Control1010022; V14Caption_Control1010022Lbl)
                {
                }
                column(V12Caption_Control1010060; V12Caption_Control1010060Lbl)
                {
                }
                column(V13Caption_Control1010061; V13Caption_Control1010061Lbl)
                {
                }
                column(V11Caption_Control1010062; V11Caption_Control1010062Lbl)
                {
                }
                column(V10Caption_Control1010063; V10Caption_Control1010063Lbl)
                {
                }
                column(V9Caption_Control1010064; V9Caption_Control1010064Lbl)
                {
                }
                column(V8Caption_Control1010066; V8Caption_Control1010066Lbl)
                {
                }
                column(V7Caption_Control1010067; V7Caption_Control1010067Lbl)
                {
                }
                column(V6Caption_Control1010070; V6Caption_Control1010070Lbl)
                {
                }
                column(V5Caption_Control1010071; V5Caption_Control1010071Lbl)
                {
                }
                column(BNBB__de_Berlaimont_14__1000_BRUCaption_Control1010072; BNBB__de_Berlaimont_14__1000_BRUCaption_Control1010072Lbl)
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
                column(Intrastat_Jnl__Line_Area; Area)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    IntraJnlManagement.ValidateReportWithAdvancedChecklist("Intrastat Jnl. Line", Report::"Intrastat - Form", true);
                    if not GLSetup."Simplified Intrastat Decl." then begin
                        TestField("Transport Method");
                        TestField("Transaction Specification");
                    end;

                    Tariffnumber.Get("Tariff No.");
                    if Tariffnumber."Weight Mandatory" then begin
                        if "Total Weight" <= 0 then
                            FieldError("Total Weight", Text11307);
                    end else
                        TestField("Supplementary Units", true);

                    if "Supplementary Units" then begin

                        if (PrevIntrastatJnlLine.Type <> Type) or
                           (PrevIntrastatJnlLine."Tariff No." <> "Tariff No.") or
                           (PrevIntrastatJnlLine."Country/Region Code" <> "Country/Region Code") or
                           (PrevIntrastatJnlLine."Transaction Type" <> "Transaction Type") or
                           (PrevIntrastatJnlLine."Transport Method" <> "Transport Method")
                        then begin
                            SubTotalWeight := 0;
                            PrevIntrastatJnlLine.SetCurrentKey(Type, "Country/Region Code", "Tariff No.", "Transaction Type", "Transport Method");
                            PrevIntrastatJnlLine.SetRange(Type, Type);
                            PrevIntrastatJnlLine.SetRange("Country/Region Code", "Country/Region Code");
                            PrevIntrastatJnlLine.SetRange("Tariff No.", "Tariff No.");
                            PrevIntrastatJnlLine.SetRange("Transaction Type", "Transaction Type");
                            PrevIntrastatJnlLine.SetRange("Transport Method", "Transport Method");
                            PrevIntrastatJnlLine.FindFirst();
                        end;

                        SubTotalWeight := SubTotalWeight + Round("Total Weight", 1);
                        TotalWeight := TotalWeight + Round("Total Weight", 1);
                        Vsupplunit := Quantity * "Conversion Factor";
                    end;

                    if "Statistical Value" <= 0 then
                        FieldError("Statistical Value", Text11307);
                    Country.Get("Country/Region Code");
                    Country.TestField("Intrastat Code");

                    if not Nihil then begin
                        TWeight := DelChr(
                            Format(Round("Total Weight", 1)), '=', DelChr(Format(Round("Total Weight", 1)), '=', '-0123456789'));
                        TUnits := DelChr(
                            Format(Round(Vsupplunit, 1)), '=', DelChr(Format(Round(Vsupplunit, 1)), '=', '-0123456789'));
                        TValue := DelChr(
                            Format(Round("Statistical Value", 1)), '=', DelChr(Format(Round("Statistical Value", 1)), '=', '-0123456789'));
                        Clear(TTransportMethod);
                        Clear(TIncoTerm);
                        Clear(TArea);
                        TTransportMethod := "Transport Method";
                        TIncoTerm := "Transaction Specification";
                        TArea := Area;
                    end;

                    if Index > 39 then begin
                        Index := 0;
                        NewPageNumber := NewPageNumber + 1;
                    end;

                    if (Temp_Code <> "Country/Region Code") or
                       (Temp_Tariff_No <> "Tariff No.") or
                       (Temp_Trans_Type <> "Transaction Type") or
                       (Temp_Trans_Method <> "Transport Method") or
                       (Temp_Trans_Specification <> "Transaction Specification") or
                       (Temp_Area <> Area)
                    then begin
                        Index := Index + 1;
                        TValue_Total := 0;
                        TWeight_Total := 0;
                    end;

                    Temp_Code := "Country/Region Code";
                    Temp_Tariff_No := "Tariff No.";
                    Temp_Trans_Type := "Transaction Type";
                    Temp_Trans_Method := "Transport Method";
                    Temp_Trans_Specification := "Transaction Specification";
                    Temp_Area := Area;
                    Text_Index := Format(Index);
                    TValue_Total := TValue_Total + "Statistical Value";
                    TWeight_Total := TWeight_Total + "Total Weight";

                    if Index < 10 then
                        Text_Index := '0' + Text_Index;
                end;

                trigger OnPreDataItem()
                begin
                    if Nihil then
                        CurrReport.Break();

                    CheckIntrastatJnlBatch();

                    // Calculate number of pages
                    if not Nihil then begin
                        Clear(IJL);
                        NumbRecords := 0;
                        IJL.SetCurrentKey(
                          Type, "Country/Region Code", "Tariff No.", "Transaction Type",
                          "Transport Method", "Transaction Specification", Area);
                        IJL.CopyFilters("Intrastat Jnl. Line");
                        if IJL.FindSet() then
                            repeat
                                Clear(IJL2);
                                IJL2.SetCurrentKey(
                                  Type, "Country/Region Code", "Tariff No.", "Transaction Type",
                                  "Transport Method", "Transaction Specification", Area);
                                IJL2.CopyFilters(IJL);
                                IJL2.SetRange(Type, IJL.Type);
                                IJL2.SetRange("Country/Region Code", IJL."Country/Region Code");
                                IJL2.SetRange("Tariff No.", IJL."Tariff No.");
                                IJL2.SetRange("Transaction Type", IJL."Transaction Type");
                                IJL2.SetRange("Transport Method", IJL."Transport Method");
                                IJL2.SetRange("Transaction Specification", IJL."Transaction Specification");
                                IJL2.SetRange(Area, IJL.Area);
                                NumbRecords := NumbRecords + 1;
                            until IJL.Next(IJL2.Count) = 0;
                        Pages := Round(NumbRecords / 40, 1, '>');
                    end;
                    Index := 0;
                    TValue_Total := 0;
                    TWeight_Total := 0;
                    NewPageNumber := 0;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                VMonth := CopyStr("Intrastat Jnl. Batch"."Statistics Period", 3, 2);
                VYear := CopyStr("Intrastat Jnl. Batch"."Statistics Period", 1, 2);

                Pages := 1;
                IntraJnlManagement.ChecklistClearBatchErrors("Intrastat Jnl. Batch");
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    group("Third party")
                    {
                        Caption = 'Third party';
                        field("Vthird[1]"; Vthird[1])
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Name';
                            ToolTip = 'Specifies the company name.';
                        }
                        field("Vthird[2]"; Vthird[2])
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Address';
                            ToolTip = 'Specifies the address.';
                        }
                        field("Vthird[3]"; Vthird[3])
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Post Code + City';
                            ToolTip = 'Specifies the post code and city of the company''s address.';
                        }
                        field("Vthird[4]"; Vthird[4])
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Contact';
                            ToolTip = 'Specifies the name of the contact person at the third party declarant, who has filled out the Intrastat declaration (and that can be contacted if necessary).';
                        }
                        field("Vthird[5]"; Vthird[5])
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Telephone';
                            ToolTip = 'Specifies the telephone number of (the contact person at) the third party declarant.';
                        }
                        field("Vthird[6]"; Vthird[6])
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Telefax';
                            ToolTip = 'Specifies the telefax number of (the contact person at) the third party declarant.';
                        }
                        field("Vthird[7]"; Vthird[7])
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'International VAT number';
                            ToolTip = 'Specifies the international VAT registration number of the third party declarant.';
                        }
                    }
                    group("Additional information")
                    {
                        Caption = 'Additional information';
                        field(Nihil; Nihil)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Nihil declaration';
                            ToolTip = 'Specifies if you do not have any trade transactions with European Union (EU) countries/regions and want to send an empty declaration.';

                            trigger OnValidate()
                            begin
                                if Nihil then
                                    VMessage := Text11311;
                            end;
                        }
                        field(VMessage; VMessage)
                        {
                            ApplicationArea = Basic, Suite;
                            Caption = 'Message';
                            ToolTip = 'Specifies a message that will be printed on the Intrastat declaration, such as "normal declaration" or "replacement declaration".';

                            trigger OnValidate()
                            begin
                                if Nihil then
                                    Error(Text11310);
                            end;
                        }
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnOpenPage()
        begin
            if not StopShowWarnMsg then
                StopShowWarnMsg := Confirm(Text11313, true);
        end;
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        GLSetup.Get();
        Company.Get();
        if not CheckVatNo.MOD97Check(Company."Enterprise No.") then
            Error(Text11315);
    end;

    trigger OnPreReport()
    begin
        if not ("Intrastat Jnl. Line".GetRangeMin(Type) = "Intrastat Jnl. Line".GetRangeMax(Type)) then
            "Intrastat Jnl. Line".FieldError(Type, Text11301);

        if "Intrastat Jnl. Line".GetRangeMin(Type) = 0 then begin
            Text1 := Text11302;
            Text2 := Text11303;
        end else begin
            Text1 := Text11304;
            Text2 := Text11305;
        end;

        Vvatno := Company."Enterprise No.";
    end;

    var
        GLSetup: Record "General Ledger Setup";
        PrevIntrastatJnlLine: Record "Intrastat Jnl. Line";
        Company: Record "Company Information";
        Country: Record "Country/Region";
        IJL: Record "Intrastat Jnl. Line";
        IJL2: Record "Intrastat Jnl. Line";
        Tariffnumber: Record "Tariff Number";
        IntraJnlManagement: Codeunit IntraJnlManagement;
        CheckVatNo: Codeunit VATLogicalTests;
        ApplicationSystemConstants: Codeunit "Application System Constants";
        SubTotalWeight: Decimal;
        TotalWeight: Decimal;
        NumbRecords: Integer;
        Vvatno: Code[20];
        Text1: Text[45];
        Text2: Text[30];
        VMonth: Text[2];
        VYear: Text[2];
        Vthird: array[8] of Text[30];
        Vsupplunit: Decimal;
        Pages: Integer;
        VMessage: Text[30];
        TWeight: Text[30];
        TUnits: Text[30];
        TValue: Text[30];
        TTransportMethod: Text[30];
        TIncoTerm: Text[30];
        TArea: Text[30];
        Nihil: Boolean;
        StopShowWarnMsg: Boolean;
        Text11301: Label 'must be Import or Export';
        Text11302: Label 'INTRASTAT 19 RECEIPT';
        Text11303: Label 'MA-1', Locked = true;
        Text11304: Label 'INTRASTAT 29 SHIPMENT';
        Text11305: Label 'MA-2', Locked = true;
        Text11307: Label 'must be more than 0';
        Text11310: Label 'No message allowed when using a Nihil declaration.';
        Text11311: Label 'NIHIL', Locked = true;
        Text11312: Label 'Report for internal use only, must not be used as an official statement';
        Text11313: Label 'This report is for internal use only and must not be used as an official declaration.\\Don''t show me this warning again?';
        Text11315: Label 'Enterprise number in the Company Information table is not valid.';
        Index: Integer;
        Temp_Code: Code[10];
        Temp_Tariff_No: Code[10];
        Temp_Trans_Type: Code[10];
        Temp_Trans_Method: Code[10];
        Temp_Trans_Specification: Code[10];
        Temp_Area: Code[10];
        Text_Index: Text[30];
        TValue_Total: Decimal;
        TWeight_Total: Decimal;
        NewPageNumber: Integer;
        V1CaptionLbl: Label '1';
        V2CaptionLbl: Label '2';
        V3CaptionLbl: Label '3';
        V4CaptionLbl: Label '4';
        XCaptionLbl: Label 'X', Locked = true;
        TELCaptionLbl: Label 'TEL';
        TELCaption_Control1010077Lbl: Label 'TEL';
        FAXCaptionLbl: Label 'FAX';
        FAXCaption_Control1010079Lbl: Label 'FAX';
        V14CaptionLbl: Label '14';
        V12CaptionLbl: Label '12';
        V13CaptionLbl: Label '13';
        V11CaptionLbl: Label '11';
        V10CaptionLbl: Label '10';
        V9CaptionLbl: Label '9';
        V8CaptionLbl: Label '8';
        V7CaptionLbl: Label '7';
        V6CaptionLbl: Label '6';
        V5CaptionLbl: Label '5';
        BNBB__de_Berlaimont_14__1000_BRUCaptionLbl: Label 'BNBB, de Berlaimont 14, 1000 BRU';
        V1Caption_Control1010008Lbl: Label '1';
        V2Caption_Control1010040Lbl: Label '2';
        V3Caption_Control1010042Lbl: Label '3';
        V4Caption_Control1010043Lbl: Label '4';
        XCaption_Control1010007Lbl: Label 'X', Locked = true;
        TELCaption_Control1010033Lbl: Label 'TEL';
        TELCaption_Control1010065Lbl: Label 'TEL';
        FAXCaption_Control1010068Lbl: Label 'FAX';
        FAXCaption_Control1010069Lbl: Label 'FAX';
        V14Caption_Control1010022Lbl: Label '14';
        V12Caption_Control1010060Lbl: Label '12';
        V13Caption_Control1010061Lbl: Label '13';
        V11Caption_Control1010062Lbl: Label '11';
        V10Caption_Control1010063Lbl: Label '10';
        V9Caption_Control1010064Lbl: Label '9';
        V8Caption_Control1010066Lbl: Label '8';
        V7Caption_Control1010067Lbl: Label '7';
        V6Caption_Control1010070Lbl: Label '6';
        V5Caption_Control1010071Lbl: Label '5';
        BNBB__de_Berlaimont_14__1000_BRUCaption_Control1010072Lbl: Label 'BNBB, de Berlaimont 14, 1000 BRU';

    local procedure CheckIntrastatJnlBatch()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckIntrastatJnlBatch("Intrastat Jnl. Batch", "Intrastat Jnl. Line", IsHandled);
        if IsHandled then
            exit;

        with "Intrastat Jnl. Line" do
            if Count() > 0 then
                if GetRangeMin(Type) = 0 then
                    "Intrastat Jnl. Batch".TestField("System 19 reported", false)
                else
                    "Intrastat Jnl. Batch".TestField("System 29 reported", false);

    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckIntrastatJnlBatch(var IntrastatJnlBatch: Record "Intrastat Jnl. Batch"; var IntrastatJnlLine: Record "Intrastat Jnl. Line"; var IsHandled: Boolean)
    begin
    end;
}
#endif
