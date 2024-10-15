// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft;

using System.Utilities;

xmlport 10720 "G/L Importing Tool"
{
    Caption = 'G/L Importing Tool';
    Direction = Import;
    FieldDelimiter = '<None>';
    FieldSeparator = '<TAB>';
    Format = VariableText;
    TableSeparator = '.<NewLine>';

    schema
    {
        textelement(Root)
        {
            tableelement(Integer; Integer)
            {
                XmlName = 'Integer';
                SourceTableView = sorting(Number) where(Number = const(1));
                UseTemporary = true;
                textelement(Header)
                {
                }
            }
#if not CLEAN25
            tableelement(newglacct; "New G/L Account")
            {
                XmlName = 'NewGLAcct';
                SourceTableView = sorting("No.");
                fieldelement(No; NewGLAcct."No.")
                {
                }
                fieldelement(Name; NewGLAcct.Name)
                {
                }
                fieldelement(AccountType; NewGLAcct."Account Type")
                {
                }
                fieldelement(IncomeBalance; NewGLAcct."Income/Balance")
                {
                }
                fieldelement(DirectPosting; NewGLAcct."Direct Posting")
                {
                }
                fieldelement(GenPostingType; NewGLAcct."Gen. Posting Type")
                {
                }
                fieldelement(GenBusPostingGroup; NewGLAcct."Gen. Bus. Posting Group")
                {
                }
                fieldelement(GenProdPostingGroup; NewGLAcct."Gen. Prod. Posting Group")
                {
                }
                fieldelement(VATBusPostingGroup; NewGLAcct."VAT Bus. Posting Group")
                {
                }
                fieldelement(VATProdPostingGroup; NewGLAcct."VAT Prod. Posting Group")
                {
                }
                fieldelement(IncomeStmtBalAcc; NewGLAcct."Income Stmt. Bal. Acc.")
                {
                }

                trigger OnPreXmlItem()
                var
                    NewGLAcct2: Record "New G/L Account";
                begin
                    RegNo := 0;

                    if NewGLAcct2.FindFirst() then
                        if not Confirm(Text1100000, false, NewGLAcct2.TableCaption()) then
                            Error(Text1100001);
                end;

                trigger OnBeforeInsertRecord()
                begin
                    NewGLAcct."Search Name" := NewGLAcct.Name;
                    RegNo := RegNo + 1;
                end;
            }
#endif
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

    trigger OnPostXmlPort()
    begin
        if RegNo = 0 then
            Error(Text1100002, RegNo);

        Message(Text1100003, RegNo);
    end;

    var
        RegNo: Integer;
#if not CLEAN25
        Text1100000: Label 'Some G/L Accounts have been found in the %1 table. Are you sure you want to replace the existing information?';
        Text1100001: Label 'The process has been cancelled by the user.';
#endif
        Text1100002: Label '%1 records have been imported. Please check that the file contained registers and try again.';
        Text1100003: Label 'The importing process has finished. %1 records have been imported.';
}

