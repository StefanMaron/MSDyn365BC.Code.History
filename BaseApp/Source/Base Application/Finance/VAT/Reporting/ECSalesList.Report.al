// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using System;
using System.IO;
using System.Utilities;

report 130 "EC Sales List"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Finance/VAT/Reporting/ECSalesList.rdlc';
    ApplicationArea = BasicEU;
    Caption = 'EC Sales List';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("Country/Region"; "Country/Region")
        {
            DataItemTableView = sorting("EU Country/Region Code") where("EU Country/Region Code" = filter(<> ''));
            column(CompanyAddr1; CompanyAddr[1])
            {
            }
            column(CompanyAddr2; CompanyAddr[2])
            {
            }
            column(CompanyAddr3; CompanyAddr[3])
            {
            }
            column(CompanyAddr4; CompanyAddr[4])
            {
            }
            column(CompanyAddr5; CompanyAddr[5])
            {
            }
            column(CompanyAddr6; CompanyAddr[6])
            {
            }
            column(CompanyAddr7; CompanyAddr[7])
            {
            }
            column(CompanyAddr8; CompanyAddr[8])
            {
            }
            column(CompanyInfoPhoneNo; CompanyInfo."Phone No.")
            {
            }
            column(CompanyInfoHomePage; CompanyInfo."Home Page")
            {
            }
            column(CompanyInfoEMail; CompanyInfo."E-Mail")
            {
            }
            column(CompanyInfoVATRegistrationNo; CompanyInfo."VAT Registration No.")
            {
            }
            column(PageCaption; StrSubstNo(Text001, ''))
            {
            }
            column(GLSetupLCYCode; StrSubstNo(Text000, GLSetup."LCY Code"))
            {
            }
            column(VATEntryTableCaptionFilter; "VAT Entry".TableCaption + ': ' + VATEntryFilter)
            {
            }
            column(VATEntryFilter; VATEntryFilter)
            {
            }
            column(ThirdPartyTrade; ThirdPartyTrade)
            {
            }
            column(NotEUTrdPartyAmtTotal; FormatNotEUTrdPartyAmt)
            {
            }
            column(NotEUTrdPartyAmtServiceTotal; FormatNotEUTrdPartyAmtService)
            {
            }
            column(FORMATTRUE; Format(true))
            {
            }
            column(EUTrdPartyAmtTotal; FormatEUTrdPartyAmt)
            {
            }
            column(EUTrdPartyAmtServiceTotal; FormatEUTrdPartyAmtService)
            {
            }
            column(ECSalesListCaption; ECSalesListCaptionLbl)
            {
            }
            column(CompanyInfoPhoneNoCaption; CompanyInfoPhoneNoCaptionLbl)
            {
            }
            column(CompanyInfoHomePageCaption; CompanyInfoHomePageCaptionLbl)
            {
            }
            column(CompanyInfoVATRegistrationNoCaption; CompanyInfoVATRegistrationNoCaptionLbl)
            {
            }
            column(TotalValueofItemSuppliesCaption; TotalValueofItemSuppliesCaptionLbl)
            {
            }
            column(EU3PartyTradeCaption; EU3PartyTradeCaptionLbl)
            {
            }
            column(TotalValueofServiceSuppliesCaption; TotalValueofServiceSuppliesCaptionLbl)
            {
            }
            column(Indicator_Code_Caption; Indicator_Code_CaptionLbl)
            {
            }
            column(EU3PartyItemTradeAmtCaption; EU3PartyItemTradeAmtCaptionLbl)
            {
            }
            column(EUPartySrvcTradeAmtCaption; EUPartySrvcTradeAmtCaptionLbl)
            {
            }
            column(NumberoflinesThispageCaption; NumberoflinesThispageCaptionLbl)
            {
            }
            column(NumberoflinesAllpagesCaption; NumberoflinesAllpagesCaptionLbl)
            {
            }
            column(CompanyInfoEMailCaption; CompanyInfoEMailCaptionLbl)
            {
            }
            dataitem("VAT Entry"; "VAT Entry")
            {
                DataItemLink = "Country/Region Code" = field(Code);
                DataItemTableView = sorting(Type, "Country/Region Code", "VAT Registration No.", "VAT Bus. Posting Group", "VAT Prod. Posting Group", "VAT Reporting Date") where(Type = const(Sale), "Country/Region Code" = filter(<> ''));
                RequestFilterFields = "VAT Bus. Posting Group", "VAT Prod. Posting Group", "VAT Reporting Date", "EU Service";
                column(VATRegNo_VATEntry; "VAT Registration No.")
                {
                }
                column(VATRegNo_VATEntryCaption; FieldCaption("VAT Registration No."))
                {
                }
                column(CountryRegionEUCountryRegionCode; "Country/Region"."EU Country/Region Code")
                {
                }
                column(CountryRegionEUCountryRegionCodeCaption; "Country/Region".FieldCaption("EU Country/Region Code"))
                {
                }
                column(NotEUTrdPartyAmt; NotEUTrdPartyAmt)
                {
                }
                column(Grouping; Grouping)
                {
                    OptionCaption = 'NotEUTrdPartyAmt,NotEUTrdPartyAmtService,EUTrdPartyAmt,EUTrdPartyAmtService';
                }
                column(IndicatorCode; IndicatorCode)
                {
                }
                column(NotEUTrdPartyAmtService; NotEUTrdPartyAmtService)
                {
                }
                column(EUTrdPartyAmt; EUTrdPartyAmt)
                {
                }
                column(EUTrdPartyAmtService; EUTrdPartyAmtService)
                {
                }

                trigger OnAfterGetRecord()
                begin
                    if ResetVATEntry then begin
                        ResetVATEntry := false;
                        NewGroupStarted := false;
                        EUTrdPartyAmtService := 0;
                        NotEUTrdPartyAmtService := 0;
                        EUTrdPartyAmt := 0;
                        NotEUTrdPartyAmt := 0
                    end;

                    if "EU Service" then
                        if "EU 3-Party Trade" then
                            EUTrdPartyAmtService += Base
                        else
                            NotEUTrdPartyAmtService += Base
                    else
                        if "EU 3-Party Trade" then
                            EUTrdPartyAmt += Base
                        else
                            NotEUTrdPartyAmt += Base;

                    if ReportLayout = ReportLayout::"Separate &Lines" then begin
                        if NotEUTrdPartyAmt <> 0 then begin
                            Grouping := Grouping::NotEUTrdPartyAmt;
                            IndicatorCode := GetIndicatorCode(false, false)
                        end;
                        if NotEUTrdPartyAmtService <> 0 then begin
                            Grouping := Grouping::NotEUTrdPartyAmtService;
                            IndicatorCode := GetIndicatorCode(false, true)
                        end;
                        if EUTrdPartyAmt <> 0 then begin
                            Grouping := Grouping::EUTrdPartyAmt;
                            IndicatorCode := GetIndicatorCode(true, false)
                        end;
                        if EUTrdPartyAmtService <> 0 then begin
                            Grouping := Grouping::EUTrdPartyAmtService;
                            IndicatorCode := GetIndicatorCode(false, true)
                        end;
                    end;

                    if not (VATEntry.Next() = 0) then begin
                        if VATEntry."VAT Registration No." = "VAT Registration No." then
                            if ReportLayout = ReportLayout::"Separate &Lines" then begin
                                if (VATEntry."EU Service" = "EU Service") and (VATEntry."EU 3-Party Trade" = "EU 3-Party Trade") then
                                    CurrReport.Skip()
                            end else
                                CurrReport.Skip();
                        ResetVATEntry := true;
                        NewGroupStarted := true;
                        PrevVATRegNo := "VAT Registration No.";
                        UpdateXMLFileRTC();
                    end;

                    TotalEUTrdPartyAmtService += Round(EUTrdPartyAmtService, 1);
                    TotalNotEUTrdPartyAmtService += Round(NotEUTrdPartyAmtService, 1);
                    TotalEUTrdPartyAmt += Round(EUTrdPartyAmt, 1);
                    TotalNotEUTrdPartyAmt += Round(NotEUTrdPartyAmt, 1);
                    FormatEUTrdPartyAmtService := FormatAmt(TotalEUTrdPartyAmtService);
                    FormatNotEUTrdPartyAmtService := FormatAmt(TotalNotEUTrdPartyAmtService);
                    FormatEUTrdPartyAmt := FormatAmt(TotalEUTrdPartyAmt);
                    FormatNotEUTrdPartyAmt := FormatAmt(TotalNotEUTrdPartyAmt);
                end;

                trigger OnPostDataItem()
                begin
                    UpdateXMLFileRTC();
                end;

                trigger OnPreDataItem()
                begin
                    ResetVATEntry := true;
                    VATEntry.SetCurrentKey(
                      Type, "Country/Region Code", "VAT Registration No.", "VAT Bus. Posting Group", "VAT Prod. Posting Group", "VAT Reporting Date");
                    VATEntry.CopyFilters("VAT Entry");
                    if not VATEntry.FindSet() then;

                    EUTrdPartyAmtService := 0;
                    NotEUTrdPartyAmtService := 0;
                    EUTrdPartyAmt := 0;
                    NotEUTrdPartyAmt := 0
                end;
            }

            trigger OnPreDataItem()
            begin
                CompanyInfo.Get();
                FormatAddr.Company(CompanyAddr, CompanyInfo);
                ThirdPartyTrade := (ReportLayout = ReportLayout::"Separate &Lines");
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
                    field(ReportLayout; ReportLayout)
                    {
                        ApplicationArea = BasicEU;
                        Caption = 'Print Third Party Trade as';
                        OptionCaption = 'Separate Lines,Column with Amount';
                        ToolTip = 'Specifies if you want the report to show third party trade as a separate line for each customer or as an additional column.';
                    }
                    field("Create XML File"; "Create XML File")
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Create XML File';
                        ToolTip = 'Specifies the calculated tax and base amounts, and creates the sales VAT advance notification XML document that will be sent to the tax authority.';

                        trigger OnValidate()
                        begin
                            CreateXMLFileOnAfterValidate();
                        end;
                    }
                }
            }
        }

        actions
        {
        }

        trigger OnInit()
        begin
            XMLFileEnable := true;
        end;

        trigger OnOpenPage()
        begin
            XMLFileEnable := "Create XML File";
        end;
    }

    labels
    {
    }

    trigger OnPostReport()
    begin
        if "Create XML File" then
            SaveXMLFile();
    end;

    trigger OnPreReport()
    var
        PeriodEnd: Date;
    begin
        CompanyInfo.Get();
        FormatAddr.Company(CompanyAddr, CompanyInfo);

        VATEntryFilter := "VAT Entry".GetFilters();
        PeriodStart := "VAT Entry".GetRangeMin("Posting Date");
        PeriodEnd := "VAT Entry".GetRangeMax("Posting Date");

        Calendar.Reset();
        Calendar.SetFilter("Period Type", '%1|%2', Calendar."Period Type"::Month, Calendar."Period Type"::Quarter);
        Calendar.SetRange("Period Start", PeriodStart);
        Calendar.SetRange("Period End", ClosingDate(PeriodEnd));
        if not Calendar.FindFirst() then
            Error(Text10500, "VAT Entry".FieldCaption("Posting Date"), "VAT Entry".GetFilter("Posting Date"));

        GLSetup.Get();

        if "Create XML File" then
            CreateXMLDocument();
    end;

    var
        GLSetup: Record "General Ledger Setup";
        CompanyInfo: Record "Company Information";
        VATEntry: Record "VAT Entry";
        FormatAddr: Codeunit "Format Address";
        VATEntryFilter: Text;
        CompanyAddr: array[8] of Text[100];
        EUTrdPartyAmt: Decimal;
        NotEUTrdPartyAmt: Decimal;
        EUTrdPartyAmtService: Decimal;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'All amounts are in whole %1.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        NotEUTrdPartyAmtService: Decimal;
        ReportLayout: Option "Separate &Lines","Column with &Amount";
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label 'Page %1';
#pragma warning restore AA0470
#pragma warning restore AA0074
        ThirdPartyTrade: Boolean;
        ResetVATEntry: Boolean;
        Grouping: Option NotEUTrdPartyAmt,NotEUTrdPartyAmtService,EUTrdPartyAmt,EUTrdPartyAmtService;
        TotalNotEUTrdPartyAmt: Decimal;
        TotalEUTrdPartyAmt: Decimal;
        TotalNotEUTrdPartyAmtService: Decimal;
        TotalEUTrdPartyAmtService: Decimal;
        FormatNotEUTrdPartyAmt: Text[30];
        FormatEUTrdPartyAmt: Text[30];
        FormatNotEUTrdPartyAmtService: Text[30];
        FormatEUTrdPartyAmtService: Text[30];
        Calendar: Record Date;
        XMLOut: DotNet XmlDocument;
        XMLCurrNode: DotNet XmlNode;
        Attribute: DotNet XmlAttribute;
        NewChildNode: DotNet XmlNode;
        NewChildNode2: DotNet XmlNode;
        NewChildNode3: DotNet XmlNode;
        "XML File": Text[1024];
        "Create XML File": Boolean;
        Text1041000: Label 'XML Files (*.xml)|*.xml|All Files (*.*)|*.*';
        Text1041001: Label 'Export to XML File';
        PeriodStart: Date;
        Text1041002: Label 'XML file successfully created';
        Text1040003: Label 'Default';
        ToFile: Text[1024];
        PrevVATRegNo: Text[30];
        NewGroupStarted: Boolean;
        XMLFileEnable: Boolean;
        Text10500: Label '%1 filter %2 must be corrected, to run the report monthly or quarterly. ';
        IndicatorCode: Integer;
        ECSalesListCaptionLbl: Label 'EC Sales List';
        CompanyInfoPhoneNoCaptionLbl: Label 'Phone No.';
        CompanyInfoHomePageCaptionLbl: Label 'Home Page';
        CompanyInfoVATRegistrationNoCaptionLbl: Label 'VAT Registration No.';
        TotalValueofItemSuppliesCaptionLbl: Label 'Total Value of Item Supplies';
        EU3PartyTradeCaptionLbl: Label 'EU 3-Party Trade';
        TotalValueofServiceSuppliesCaptionLbl: Label 'Total Value of Service Supplies';
        Indicator_Code_CaptionLbl: Label 'Indicator Code';
        EU3PartyItemTradeAmtCaptionLbl: Label 'EU 3-Party Item Trade Amount';
        EUPartySrvcTradeAmtCaptionLbl: Label 'EU 3-Party Service Trade Amount';
        NumberoflinesThispageCaptionLbl: Label 'Number of lines (this page)';
        NumberoflinesAllpagesCaptionLbl: Label 'Number of lines (all pages)';
        CompanyInfoEMailCaptionLbl: Label 'Email';

    local procedure FormatAmt(AmountToPrint: Decimal): Text[30]
    var
        TextAmt: Text[30];
    begin
        TextAmt := Format(Round(-AmountToPrint, 1), 0, '<Integer Thousand><Decimals>');
        if AmountToPrint > 0 then
            TextAmt := '(' + TextAmt + ')';
        exit(TextAmt);
    end;

    procedure InitializeRequest(NewReportLayout: Option)
    begin
        ReportLayout := NewReportLayout;
    end;

    [Scope('OnPrem')]
    procedure CreateXMLDocument()
    var
        RBMgt: Codeunit "File Management";
    begin
        "XML File" := RBMgt.ServerTempFileName('xml');
        XMLOut := XMLOut.XmlDocument();


        XMLCurrNode := XMLOut.CreateElement('Submission');
        Attribute := XMLOut.CreateAttribute('type');
        Attribute.Value := 'HMCE_VAT_ESL_BULK_SUBMISSION_FILE';
        XMLCurrNode.Attributes.SetNamedItem(Attribute);
        XMLOut.AppendChild(XMLCurrNode);

        XMLOut.CreateProcessingInstruction('xml', 'version="1.0" encoding="utf-8"');

        NewChildNode := XMLOut.CreateElement('TraderVRN');
        NewChildNode.InnerText(CompanyInfo."VAT Registration No.");
        XMLCurrNode.AppendChild(NewChildNode);

        NewChildNode := XMLOut.CreateElement('Branch');
        NewChildNode.InnerText(CompanyInfo."Branch Number");
        XMLCurrNode.AppendChild(NewChildNode);

        NewChildNode := XMLOut.CreateElement('Year');
        NewChildNode.InnerText(Format(Date2DMY(PeriodStart, 3)));
        XMLCurrNode.AppendChild(NewChildNode);

        NewChildNode := XMLOut.CreateElement('Period');
        NewChildNode.InnerText(FormatPeriod(Calendar."Period No." * CalcPeriodValue()));
        XMLCurrNode.AppendChild(NewChildNode);

        NewChildNode := XMLOut.CreateElement('CurrencyA3');
        NewChildNode.InnerText(GLSetup."LCY Code");
        XMLCurrNode.AppendChild(NewChildNode);

        NewChildNode := XMLOut.CreateElement('ContactName');
        NewChildNode.InnerText(CompanyInfo."Contact Person");
        XMLCurrNode.AppendChild(NewChildNode);

        NewChildNode := XMLOut.CreateElement('Online');
        NewChildNode.InnerText('0');
        XMLCurrNode.AppendChild(NewChildNode);

        NewChildNode := XMLOut.CreateElement('SubmissionLines');
    end;

    [Scope('OnPrem')]
    procedure CreateXMLSubmissionLine(Amount: Decimal; IndicatorCode: Integer)
    begin
        NewChildNode2 := XMLOut.CreateElement('SubmissionLine');

        NewChildNode3 := XMLOut.CreateElement('CountryA2');
        NewChildNode3.InnerText("Country/Region"."EU Country/Region Code");

        NewChildNode.AppendChild(NewChildNode2);
        NewChildNode2.AppendChild(NewChildNode3);

        NewChildNode3 := XMLOut.CreateElement('CustomerVRN');
        if NewGroupStarted then
            NewChildNode3.InnerText(PrevVATRegNo)
        else
            NewChildNode3.InnerText("VAT Entry"."VAT Registration No.");
        NewChildNode2.AppendChild(NewChildNode3);

        NewChildNode3 := XMLOut.CreateElement('Value');
        NewChildNode3.InnerText(FormatAmtXML(Amount));
        NewChildNode2.AppendChild(NewChildNode3);
        NewChildNode3 := XMLOut.CreateElement('Indicator');
        NewChildNode3.InnerText(Format(IndicatorCode));
        NewChildNode2.AppendChild(NewChildNode3);
        XMLCurrNode.AppendChild(NewChildNode);
    end;

    [Scope('OnPrem')]
    procedure SaveXMLFile()
    begin
        XMLOut.Save("XML File");
        ToFile := Text1040003 + '.xml';
        if not Download("XML File", Text1041001, '', Text1041000, ToFile) then
            exit;
        Message(Text1041002);
    end;

    local procedure FormatAmtXML(AmountToPrint: Decimal): Text[30]
    begin
        exit(Format(Round(-AmountToPrint, 1), 0, 1));
    end;

    [Scope('OnPrem')]
    procedure UpdateXMLFileRTC()
    var
        IndicatorCode2: Integer;
    begin
        if "Create XML File" and
           (NotEUTrdPartyAmt <> 0)
        then begin
            IndicatorCode2 := GetIndicatorCode(false, false);
            CreateXMLSubmissionLine(NotEUTrdPartyAmt, IndicatorCode2);
        end;

        if "Create XML File" and (NotEUTrdPartyAmtService <> 0) then begin
            IndicatorCode2 := GetIndicatorCode(false, true);
            CreateXMLSubmissionLine(NotEUTrdPartyAmtService, IndicatorCode2);
        end;
        if "Create XML File" and
           (EUTrdPartyAmt <> 0)
        then begin
            IndicatorCode2 := GetIndicatorCode(true, false);
            CreateXMLSubmissionLine(EUTrdPartyAmt, IndicatorCode2);
        end;
    end;

    local procedure CreateXMLFileOnAfterValidate()
    begin
        XMLFileEnable := "Create XML File";
    end;

    [Scope('OnPrem')]
    procedure CalcPeriodValue(): Integer
    begin
        if Calendar."Period Type" = Calendar."Period Type"::Month then
            exit(1)
        else
            exit(3)
    end;

    [Scope('OnPrem')]
    procedure FormatPeriod(PeriodNo: Integer): Text[30]
    begin
        exit(Format(PeriodNo, 2, '<Integer,2><Filler Character,0>'));
    end;

    [Scope('OnPrem')]
    procedure GetIndicatorCode(EU3rdPartyTrade: Boolean; EUService: Boolean): Integer
    begin
        if EUService then
            exit(3)
        else
            if EU3rdPartyTrade then
                exit(2)
            else
                exit(0)
    end;
}

