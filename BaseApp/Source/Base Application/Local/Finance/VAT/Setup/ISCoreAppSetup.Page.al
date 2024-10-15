#if not CLEAN24
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance;

page 10903 "IS Core App Setup"
{
    AdditionalSearchTerms = 'Iceland, localization';
    ApplicationArea = Basic, Suite;
    Caption = 'Iceland Core App Setup';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = Card;
    SourceTable = "IS Core App Setup";
    UsageCategory = Administration;
    ObsoleteReason = 'Used to enable the IS Core App.';
    ObsoleteState = Pending;
    ObsoleteTag = '24.0';

    layout
    {
        area(content)
        {
            group(General)
            {
                field(Enabled; Rec.Enabled)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether the Iceland Core app is enabled.';
                    Enabled = not Rec.Enabled;

                    trigger OnValidate()
                    begin
                        if xRec.Enabled then
                            Error(AppAlreadyEnabledErr);
                        Error('');
                    end;
                }
                label(NotificationPart)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'The Iceland Core app covers a set of basic features for Icelandic localization. This process includes data migration, so after enabling this app, it is not possible to disable it again.';
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.Reset();
        if not Rec.Get() then begin
            Rec.Init();
            Rec.Insert();
        end;
    end;

    var
        AppAlreadyEnabledErr: Label 'The Iceland Core app has already been enabled and it cannot be disabled.';
}

#endif