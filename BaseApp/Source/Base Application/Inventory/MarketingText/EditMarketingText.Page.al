#if not CLEAN24
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.MarketingText;

using Microsoft.Inventory.Item;
using System.Text;

page 5835 "Edit Marketing Text"
{
    ObsoleteState = Pending;
    ObsoleteReason = 'This has been moved to use the new pagetype StandardDialog. Use page 5839 "Modify Marketing Text" instead.';
    ObsoleteTag = '24.0';
    Caption = 'Edit Marketing Text';
    DelayedInsert = true;
    SourceTableTemporary = true;
    InsertAllowed = false;
    DeleteAllowed = false;
    LinksAllowed = false;
    PageType = Card;
    Extensible = false;
    SourceTable = "Entity Text";
    DataCaptionExpression = ItemDescription;

    layout
    {
        area(content)
        {

            group(EntityTextGroup)
            {
                ShowCaption = false;
                field("Entity Text Editor"; EntityTextContent)
                {
                    MultiLine = true;
                    ApplicationArea = All;
                    ExtendedDatatype = RichContent;
                    ShowCaption = false;
                    StyleExpr = false;
                }
            }

            field(CopilotText; 'Get help writing engaging texts based on the item''s attributes')
            {
                Visible = IsCopilotEnabled;
                Editable = false;
                ShowCaption = false;
                ApplicationArea = All;
            }
            field(CopilotPrompt; 'Draft with Copilot')
            {
                Visible = IsCopilotEnabled;
                Editable = false;
                ShowCaption = false;
                ApplicationArea = All;

                trigger OnDrillDown()
                var
                    MarketingText: Codeunit "Marketing Text";
                    Action: Action;
                begin
                    MarketingText.CreateWithCopilot(Rec, PromptMode::Generate, Action);
                    if Action = Action::OK then begin
                        EntityTextContent := EntityText.GetText(Rec);
                        CurrPage.Update(false);
                    end;
                end;
            }
        }
    }

    trigger OnInit()
    begin
        IsCopilotEnabled := EntityText.CanSuggest()
    end;

    trigger OnAfterGetCurrRecord()
    var
        Item: Record Item;
    begin
        if HasLoaded then
            exit;

        Item.GetBySystemId(Rec."Source System Id");
        ItemDescription := Item.Description;
        EntityTextContent := EntityText.GetText(Rec);
        HasLoaded := true;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if not (CloseAction in [Action::OK, Action::LookupOK]) then
            exit(true);
        EntityText.UpdateText(Rec, EntityTextContent);
        Rec.Modify();
    end;

    var
        EntityText: Codeunit "Entity Text";
        ItemDescription: Text;
        EntityTextContent: Text;
        IsCopilotEnabled: Boolean;
        HasLoaded: Boolean;
}
#endif