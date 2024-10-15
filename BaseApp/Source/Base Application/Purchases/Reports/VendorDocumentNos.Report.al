namespace Microsoft.Purchases.Reports;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.NoSeries;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;
using System.Utilities;

report 328 "Vendor Document Nos."
{
    DefaultLayout = RDLC;
    RDLCLayout = './Purchases/Reports/VendorDocumentNos.rdlc';
    Caption = 'Vendor Document Nos.';
    ObsoleteState = Pending;
    ObsoleteReason = 'Infrequently used report.';
    ObsoleteTag = '18.0';

    dataset
    {
        dataitem("Vendor Ledger Entry"; "Vendor Ledger Entry")
        {
            DataItemTableView = sorting("Document No.");
            RequestFilterFields = "Document Type", "Document No.";
            column(COMPANYNAME; COMPANYPROPERTY.DisplayName())
            {
            }
            column(STRSUBSTNO_Text004_VendLedgerEntryFilter_; StrSubstNo(Text004, VendLedgerEntryFilter))
            {
            }
            column(VendLedgerEntryFilter; VendLedgerEntryFilter)
            {
            }
            column(PageGroupNo; PageGroupNo)
            {
            }
            column(Vendor_Ledger_Entry_Entry_No_; "Entry No.")
            {
            }
            column(Vendor_Document_Nos_Caption; Vendor_Document_Nos_CaptionLbl)
            {
            }
            column(CurrReport_PAGENOCaption; CurrReport_PAGENOCaptionLbl)
            {
            }
            column(VendLedgerEntry__Document_No__Caption; VendLedgerEntry.FieldCaption("Document No."))
            {
            }
            column(VendLedgerEntry__Source_Code_Caption; VendLedgerEntry.FieldCaption("Source Code"))
            {
            }
            column(VendLedgerEntry__User_ID_Caption; VendLedgerEntry.FieldCaption("User ID"))
            {
            }
            column(Vend_NameCaption; Vend_NameCaptionLbl)
            {
            }
            column(VendLedgerEntry__Vendor_No__Caption; VendLedgerEntry.FieldCaption("Vendor No."))
            {
            }
            column(SourceCode_DescriptionCaption; SourceCode_DescriptionCaptionLbl)
            {
            }
            column(VendLedgerEntry__Posting_Date_Caption; VendLedgerEntry__Posting_Date_CaptionLbl)
            {
            }
            column(VendLedgerEntry__Document_Type_Caption; VendLedgerEntry.FieldCaption("Document Type"))
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
            dataitem(VendLedgerEntry; "Vendor Ledger Entry")
            {
                DataItemLink = "Entry No." = field("Entry No.");
                DataItemTableView = sorting("Entry No.");
                column(VendLedgerEntry__User_ID_; "User ID")
                {
                }
                column(SourceCode_Description; SourceCode.Description)
                {
                }
                column(VendLedgerEntry__Source_Code_; "Source Code")
                {
                }
                column(Vend_Name; Vend.Name)
                {
                }
                column(VendLedgerEntry__Vendor_No__; "Vendor No.")
                {
                }
                column(VendLedgerEntry__Document_No__; "Document No.")
                {
                }
                column(VendLedgerEntry__Posting_Date_; Format("Posting Date"))
                {
                }
                column(VendLedgerEntry__Document_Type_; "Document Type")
                {
                }
            }

            trigger OnAfterGetRecord()
            begin
                if "Vendor No." <> Vend."No." then
                    if not Vend.Get("Vendor No.") then
                        Vend.Init();
                if "Source Code" <> SourceCode.Code then
                    if not SourceCode.Get("Source Code") then
                        SourceCode.Init();
                if "No. Series" <> NoSeries.Code then
                    if not NoSeries.Get("No. Series") then
                        NoSeries.Init();

                if ("No. Series" <> LastNoSeriesCode) or ("Document Type" <> LastDocType) or FirstRecord then begin
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
                    if LastDocNo <> '' then
                        if not ("Document No." in [LastDocNo, IncStr(LastDocNo)]) then
                            AddError(Text002)
                        else
                            if "Posting Date" < LastPostingDate then
                                AddError(Text003);
                    NewPage := false;
                end;

                LastDocType := "Document Type";
                LastDocNo := "Document No.";
                LastPostingDate := "Posting Date";
                LastNoSeriesCode := "No. Series";
                FirstRecord := false;
            end;

            trigger OnPreDataItem()
            begin
                FirstRecord := true;
                PageGroupNo := 1;
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
        VendLedgerEntryFilter := "Vendor Ledger Entry".GetFilters();
    end;

    var
        Vend: Record Vendor;
        NoSeries: Record "No. Series";
        SourceCode: Record "Source Code";
        VendLedgerEntryFilter: Text;
        LastDocNo: Code[20];
        LastDocType: Enum "Gen. Journal Document Type";
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
        Text004: Label 'Vendor Entry: %1';
        Vendor_Document_Nos_CaptionLbl: Label 'Vendor Document Nos.';
        CurrReport_PAGENOCaptionLbl: Label 'Page';
        Vend_NameCaptionLbl: Label 'Vendor Name';
        SourceCode_DescriptionCaptionLbl: Label 'Source Description';
        VendLedgerEntry__Posting_Date_CaptionLbl: Label 'Posting Date';
        ErrorText_Number__Control15CaptionLbl: Label 'Warning!';

    local procedure AddError(Text: Text[250])
    begin
        ErrorCounter := ErrorCounter + 1;
        ErrorText[ErrorCounter] := Text;
    end;
}

