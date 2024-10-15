namespace Microsoft.Sales.Reports;

using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.NoSeries;
using Microsoft.Sales.History;
using System.Utilities;

report 125 "Sales Credit Memo Nos."
{
    DefaultLayout = RDLC;
    RDLCLayout = './Sales/Reports/SalesCreditMemoNos.rdlc';
    Caption = 'Sales Credit Memo Nos.';
    ObsoleteState = Pending;
    ObsoleteReason = 'Infrequently used report.';
    ObsoleteTag = '18.0';

    dataset
    {
        dataitem("Sales Cr.Memo Header"; "Sales Cr.Memo Header")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.";
            RequestFilterHeading = 'Posted Sales Credit Memo';
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(STRSUBSTNO_Text004_SalesCrMemoHeaderFilter_; StrSubstNo(Text004, SalesCrMemoHeaderFilter))
            {
            }
            column(SalesCrMemoHeaderFilter; SalesCrMemoHeaderFilter)
            {
            }
            column(PageGroupNo; PageGroupNo)
            {
            }
            column(Sales_Cr_Memo_Header_No_; "No.")
            {
            }
            column(Sales_Credit_Memo_Nos_Caption; Sales_Credit_Memo_Nos_CaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(SalesCrMemoHeader__No__Caption; SalesCrMemoHeader.FieldCaption("No."))
            {
            }
            column(SalesCrMemoHeader__Source_Code_Caption; SalesCrMemoHeader.FieldCaption("Source Code"))
            {
            }
            column(SalesCrMemoHeader__User_ID_Caption; SalesCrMemoHeader.FieldCaption("User ID"))
            {
            }
            column(SalesCrMemoHeader__Bill_to_Name_Caption; SalesCrMemoHeader.FieldCaption("Bill-to Name"))
            {
            }
            column(SalesCrMemoHeader__Bill_to_Customer_No__Caption; SalesCrMemoHeader.FieldCaption("Bill-to Customer No."))
            {
            }
            column(SourceCode_DescriptionCaption; SourceCode_DescriptionCaptionLbl)
            {
            }
            column(SalesCrMemoHeader__Posting_Date_Caption; SalesCrMemoHeader__Posting_Date_CaptionLbl)
            {
            }
            dataitem(ErrorLoop; "Integer")
            {
                DataItemTableView = sorting(Number);
                column(ErrorText_Number_; ErrorText[Number])
                {
                }
                column(NewPage; NewPage)
                {
                }
                column(ErrorText_Number__Control15; ErrorText[Number])
                {
                }
                column(ErrorText_Number__Control15Caption; ErrorText_Number__Control15CaptionLbl)
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
            dataitem(SalesCrMemoHeader; "Sales Cr.Memo Header")
            {
                DataItemLink = "No." = field("No.");
                DataItemTableView = sorting("No.");
                column(SalesCrMemoHeader__User_ID_; "User ID")
                {
                }
                column(SourceCode_Description; SourceCode.Description)
                {
                }
                column(SalesCrMemoHeader__Source_Code_; "Source Code")
                {
                }
                column(SalesCrMemoHeader__Bill_to_Name_; "Bill-to Name")
                {
                }
                column(SalesCrMemoHeader__Bill_to_Customer_No__; "Bill-to Customer No.")
                {
                }
                column(SalesCrMemoHeader__No__; "No.")
                {
                }
                column(SalesCrMemoHeader__Posting_Date_; Format("Posting Date"))
                {
                }
            }

            trigger OnAfterGetRecord()
            begin
                if "Source Code" <> SourceCode.Code then
                    if not SourceCode.Get("Source Code") then
                        SourceCode.Init();
                if "No. Series" <> NoSeries.Code then
                    if not NoSeries.Get("No. Series") then
                        NoSeries.Init();

                if ("No. Series" <> LastNoSeriesCode) or FirstRecord then begin
                    if "No. Series" = '' then
                        AddError(Text000)
                    else
                        AddError(
                          StrSubstNo(
                            Text001,
                            "No. Series", NoSeries.Description));
                    if not FirstRecord then
                        PageGroupNo := PageGroupNo + 1;
                    NewPage := true;
                end else begin
                    if LastNo <> '' then
                        if not ("No." in [LastNo, IncStr(LastNo)]) then
                            AddError(Text002)
                        else
                            if "Posting Date" < LastPostingDate then
                                AddError(Text003);
                    NewPage := false;
                end;

                LastNo := "No.";
                LastPostingDate := "Posting Date";
                LastNoSeriesCode := "No. Series";
                FirstRecord := false;
            end;

            trigger OnPreDataItem()
            begin
                PageGroupNo := 1;
                FirstRecord := true;
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
        SalesCrMemoHeaderFilter := "Sales Cr.Memo Header".GetFilters();
    end;

    var
        NoSeries: Record "No. Series";
        SourceCode: Record "Source Code";
        SalesCrMemoHeaderFilter: Text;
        LastNo: Code[20];
        LastPostingDate: Date;
        LastNoSeriesCode: Code[20];
        FirstRecord: Boolean;
        NewPage: Boolean;
        ErrorText: array[10] of Text[250];
        ErrorCounter: Integer;
        PageGroupNo: Integer;

        Text000: Label 'No number series has been used for the following entries:';
        Text001: Label 'The number series %1 %2 has been used for the following entries:';
        Text002: Label 'There is a gap in the number series.';
        Text003: Label 'The documents are not listed according to Posting Date because they were not entered in that order.';
        Text004: Label 'Posted Sales Credit Memo: %1';
        Sales_Credit_Memo_Nos_CaptionLbl: Label 'Sales Credit Memo Nos.';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        SourceCode_DescriptionCaptionLbl: Label 'Source Description';
        SalesCrMemoHeader__Posting_Date_CaptionLbl: Label 'Posting Date';
        ErrorText_Number__Control15CaptionLbl: Label 'Warning!';

    local procedure AddError(Text: Text[250])
    begin
        ErrorCounter := ErrorCounter + 1;
        ErrorText[ErrorCounter] := Text;
    end;
}

