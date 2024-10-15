// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

page 746 "VAT Reports Configuration"
{
    ApplicationArea = VAT;
    Caption = 'VAT Reports Configuration';
    PageType = List;
    SourceTable = "VAT Reports Configuration";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("VAT Report Type"; Rec."VAT Report Type")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies if you want to create a new VAT report, or if you want to change a previously submitted report.';
                }
                field("VAT Report Version"; Rec."VAT Report Version")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the version of the VAT report.';
                }
                field("Suggest Lines Codeunit ID"; Rec."Suggest Lines Codeunit ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether an ID is suggested automatically.';
                }
                field("Suggest Lines Codeunit Caption"; Rec."Suggest Lines Codeunit Caption")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies whether a caption is suggested automatically.';
                }
                field("Content Codeunit ID"; Rec."Content Codeunit ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the codeunit ID.';
                }
                field("Content Codeunit Caption"; Rec."Content Codeunit Caption")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the codeunit caption code.';
                }
                field("Submission Codeunit ID"; Rec."Submission Codeunit ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the ID associated with the submission codeunit.';
                }
                field("Submission Codeunit Caption"; Rec."Submission Codeunit Caption")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the caption associated with the submission codeunit.';
                }
                field("Response Handler Codeunit ID"; Rec."Response Handler Codeunit ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the codeunit ID of the response handler.';
                }
                field("Resp. Handler Codeunit Caption"; Rec."Resp. Handler Codeunit Caption")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the caption that related to the line.';
                }
                field("Validate Codeunit ID"; Rec."Validate Codeunit ID")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the codeunit ID for the VAT Report line.';
                }
                field("Validate Codeunit Caption"; Rec."Validate Codeunit Caption")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the caption for the codeunit VAT Report.';
                }
                field("Content Max Lines"; Rec."Content Max Lines")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Max. No. of Lines';
                    ToolTip = 'Specifies the maximum number of lines in each message.';

                    trigger OnValidate()
                    begin
                        if
                           (Rec."VAT Report Type" = Rec."VAT Report Type"::"VAT Return") and
                           (Rec."Content Max Lines" <> 0)
                        then
                            Error(NotApplicableErr);

                        if Rec."Content Max Lines" < 0 then
                            Error(MinValueErr);
                    end;
                }
            }
        }
    }

    actions
    {
    }

    var
        NotApplicableErr: Label 'This value is only applicable for EC Sales list report.';
        MinValueErr: Label 'The value of Max. No. of Lines must be bigger than zero.';
}

