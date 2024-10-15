#if not CLEAN24
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.MarketingText;

page 5834 "Marketing Text Attributes"
{
    ObsoleteState = Pending;
    ObsoleteReason = 'Changed to ListPart type to integrate with Marketing Text Prompt Dialog page. Use page 5838 "Marketing Text Attributes Part" instead.';
    ObsoleteTag = '24.0';
    PageType = List;
    ApplicationArea = All;
    SourceTable = "Marketing Text Attributes";
    SourceTableTemporary = true;
    InsertAllowed = false;
    DeleteAllowed = false;
    Caption = 'Item attributes to include';

    layout
    {
        area(Content)
        {
            repeater(Attributes)
            {
                field(Property; Rec.Property)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Attribute';
                    ToolTip = 'Specifies the name of the attribute.';
                    Editable = false;
                    Enabled = false;
                }

                field(Value; Rec.Value)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Value';
                    ToolTip = 'Specifies the value of the attribute.';
                    Editable = false;
                    Enabled = false;
                }

                field(Selected; Rec.Selected)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Include';
                    Width = 5;
                    ToolTip = 'Specifies if the attribute should be included.';

                    trigger OnValidate()
                    var
                        MaxSelections: Integer;
                    begin
                        if not Rec.Selected then
                            exit;

                        Rec.SetRange(Selected, true);

                        MaxSelections := 15;

                        if Rec.Count() > (MaxSelections - 1) then // excludes this current selection
                            Error(MaxSelectionExceededErr, MaxSelections);

                        Rec.SetRange(Selected);
                    end;
                }
            }
        }
    }
    var
        MaxSelectionExceededErr: Label 'You can only select up to %1 attributes', Comment = '%1 is the number of maximum attributes';
}
#endif