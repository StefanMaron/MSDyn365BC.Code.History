// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Reports;

using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.NoSeries;
using Microsoft.Purchases.History;
using System.Utilities;

report 325 "Purchase Credit Memo Nos."
{
    DefaultLayout = RDLC;
    RDLCLayout = './Purchases/Reports/PurchaseCreditMemoNos.rdlc';
    Caption = 'Purchase Credit Memo Nos.';
    ObsoleteState = Pending;
    ObsoleteReason = 'Infrequently used report.';
    ObsoleteTag = '18.0';

    dataset
    {
        dataitem("Purch. Cr. Memo Hdr."; "Purch. Cr. Memo Hdr.")
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.";
            RequestFilterHeading = 'Posted Purchase Credit Memo';
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(STRSUBSTNO_Text004_PurchCrMemoHeaderFilter_; StrSubstNo(Text004, PurchCrMemoHeaderFilter))
            {
            }
            column(PurchCrMemoHeaderFilter; PurchCrMemoHeaderFilter)
            {
            }
            column(PageGroupNo; PageGroupNo)
            {
            }
            column(Purch__Cr__Memo_Hdr__No_; "No.")
            {
            }
            column(Purchase_Credit_Memo_Nos_Caption; Purchase_Credit_Memo_Nos_CaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(PurchCrMemoHeader__No__Caption; PurchCrMemoHeader.FieldCaption("No."))
            {
            }
            column(PurchCrMemoHeader__Source_Code_Caption; PurchCrMemoHeader.FieldCaption("Source Code"))
            {
            }
            column(PurchCrMemoHeader__User_ID_Caption; PurchCrMemoHeader.FieldCaption("User ID"))
            {
            }
            column(PurchCrMemoHeader__Pay_to_Name_Caption; PurchCrMemoHeader.FieldCaption("Pay-to Name"))
            {
            }
            column(PurchCrMemoHeader__Pay_to_Vendor_No__Caption; PurchCrMemoHeader.FieldCaption("Pay-to Vendor No."))
            {
            }
            column(SourceCode_DescriptionCaption; SourceCode_DescriptionCaptionLbl)
            {
            }
            column(PurchCrMemoHeader__Posting_Date_Caption; PurchCrMemoHeader__Posting_Date_CaptionLbl)
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
            dataitem(PurchCrMemoHeader; "Purch. Cr. Memo Hdr.")
            {
                DataItemLink = "No." = field("No.");
                DataItemTableView = sorting("No.");
                column(PurchCrMemoHeader__User_ID_; "User ID")
                {
                }
                column(SourceCode_Description; SourceCode.Description)
                {
                }
                column(PurchCrMemoHeader__Source_Code_; "Source Code")
                {
                }
                column(PurchCrMemoHeader__Pay_to_Name_; "Pay-to Name")
                {
                }
                column(PurchCrMemoHeader__Pay_to_Vendor_No__; "Pay-to Vendor No.")
                {
                }
                column(PurchCrMemoHeader__No__; "No.")
                {
                }
                column(PurchCrMemoHeader__Posting_Date_; Format("Posting Date"))
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
        PurchCrMemoHeaderFilter := "Purch. Cr. Memo Hdr.".GetFilters();
    end;

    var
        Text000: Label 'No number series has been used for the following entries:';
        Text001: Label 'The number series %1 %2 has been used for the following entries:';
        Text002: Label 'There is a gap in the number series.';
        Text003: Label 'The documents are not listed according to Posting Date because they were not entered in that order.';
        Text004: Label 'Posted Purchase Credit Memo: %1';
        NoSeries: Record "No. Series";
        SourceCode: Record "Source Code";
        PurchCrMemoHeaderFilter: Text;
        LastNo: Code[20];
        LastPostingDate: Date;
        LastNoSeriesCode: Code[20];
        FirstRecord: Boolean;
        NewPage: Boolean;
        ErrorText: array[10] of Text[250];
        ErrorCounter: Integer;
        PageGroupNo: Integer;
        Purchase_Credit_Memo_Nos_CaptionLbl: Label 'Purchase Credit Memo Nos.';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        SourceCode_DescriptionCaptionLbl: Label 'Source Description';
        PurchCrMemoHeader__Posting_Date_CaptionLbl: Label 'Posting Date';
        ErrorText_Number__Control15CaptionLbl: Label 'Warning!';

    local procedure AddError(Text: Text[250])
    begin
        ErrorCounter := ErrorCounter + 1;
        ErrorText[ErrorCounter] := Text;
    end;
}

