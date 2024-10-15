// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.VAT.Setup;

report 10911 "IRS Details"
{
    DefaultLayout = RDLC;
    RDLCLayout = './Local/Finance/VAT/Reporting/IRSDetails.rdlc';
    ApplicationArea = Basic, Suite;
    Caption = 'IRS Details';
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem("IRS Numbers"; "IRS Numbers")
        {
            DataItemTableView = sorting("IRS Number") order(Ascending);
            PrintOnlyIfDetail = true;
            RequestFilterFields = "IRS Number";
            column(CompanyName; COMPANYPROPERTY.DisplayName())
            {
            }
            column(Today; Today)
            {
            }
            column(DateFil; DateFil)
            {
            }
            column(IRSNumber_IRSNumbers; "IRS Number")
            {
            }
            column(Name_IRSNumbers; Name)
            {
            }
            column(NoCaption_GLAcc; "G/L Account".FieldCaption("No."))
            {
            }
            column(NameCaption_GLAcc; "G/L Account".FieldCaption(Name))
            {
            }
            column(BalanceAtDateCaption_GLAcc; "G/L Account".FieldCaption("Balance at Date"))
            {
            }
            column(IRSDetailsCaption; IRSDetailsCaptionLbl)
            {
            }
            column(EmptyStringCaption; EmptyStringCaptionLbl)
            {
            }
            column(ValueinIRSnumberlistCaption; ValueinIRSnumberlistCaptionLbl)
            {
            }
            column(GenPostTypeCaption_GLAcc; "G/L Account".FieldCaption("Gen. Posting Type"))
            {
            }
            column(GenProdPostGroupCaption_GLAcc; "G/L Account".FieldCaption("Gen. Prod. Posting Group"))
            {
            }
            dataitem("G/L Account"; "G/L Account")
            {
                CalcFields = "Balance at Date";
                DataItemLink = "IRS Number" = field("IRS Number");
                DataItemTableView = sorting("IRS Number", "No.") ORDER(Ascending) where("Account Type" = const(Posting));
                RequestFilterFields = "Date Filter";
                column(No_GLAcc; "No.")
                {
                }
                column(Name_GLAcc; Name)
                {
                }
                column(BalanceAtDate_GLAcc; "Balance at Date")
                {
                }
                column("Sum"; Sum)
                {
                }
                column(GenPostType_GLAcc; "Gen. Posting Type")
                {
                }
                column(GenProdPostGroup_GLAcc; "Gen. Prod. Posting Group")
                {
                }
                column(TotSum; TotSum)
                {
                }
                column(EmptyStringCaption1; EmptyStringCaption1Lbl)
                {
                }
                column(IRSNumber_GLAcc; "IRS Number")
                {
                }
            }
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
        DateFil := "G/L Account".GetFilter("Date Filter");
    end;

    var
        "Sum": Decimal;
        TotSum: Decimal;
        DateFil: Text[30];
        IRSDetailsCaptionLbl: Label 'IRS Details';
        EmptyStringCaptionLbl: Label '--------------------------------------------------------------------------------';
        ValueinIRSnumberlistCaptionLbl: Label 'Value in IRS number list';
        EmptyStringCaption1Lbl: Label '------------------------------';
}

