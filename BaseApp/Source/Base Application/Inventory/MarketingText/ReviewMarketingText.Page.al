#if not CLEAN24
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.MarketingText;

using Microsoft.Inventory.Item;
using System.Text;

page 5825 "Review Marketing Text"
{

    ObsoleteState = Pending;
    ObsoleteReason = 'This has been moved to use the new pagetype PromptDialog. Use page 5836 "Copilot Marketing Text" instead.';
    ObsoleteTag = '24.0';
    Caption = 'Create with Copilot';
    DelayedInsert = true;
    SourceTableTemporary = true;
    InsertAllowed = false;
    DeleteAllowed = false;
    LinksAllowed = false;
    PageType = Card;
    Extensible = false;
    SourceTable = "Entity Text";
    DataCaptionExpression = '';

    layout
    {
        area(content)
        {
            label(Description)
            {
                ApplicationArea = Basic, Suite;
                CaptionClass = DescriptionValue;
            }

            field(Attributes; Attributes)
            {
                Caption = 'Attributes to include';
                AssistEdit = true;
                ApplicationArea = Basic, Suite;
                Editable = false;
                Enabled = CanSelectAttributes;
                ToolTip = 'Specifies the attributes to use in the text.';

                trigger OnAssistEdit()
                var
                    TempMarketingTextAttributes: Record "Marketing Text Attributes" temporary;
                    FactKey: Text;
                    ProductName: Text;
                    ItemCategory: Text;
                    FactCount: Integer;
                    MaxFacts: Integer;
                begin
                    if AllFacts.ContainsKey(ProductNameTxt) then
                        AllFacts.Get(ProductNameTxt, ProductName);

                    if AllFacts.ContainsKey(ItemCategoryTxt) then
                        AllFacts.Get(ItemCategoryTxt, ItemCategory);

                    foreach FactKey in AllFacts.Keys() do
                        if not (FactKey in [ProductNameTxt, ItemCategoryTxt]) then begin
                            TempMarketingTextAttributes.Init();
                            TempMarketingTextAttributes.Selected := Facts.ContainsKey(FactKey);
                            TempMarketingTextAttributes.Property := CopyStr(FactKey, 1, MaxStrLen(TempMarketingTextAttributes.Property));
                            TempMarketingTextAttributes.Value := CopyStr(AllFacts.Get(FactKey), 1, MaxStrLen(TempMarketingTextAttributes.Value));
                            TempMarketingTextAttributes.Insert();
                        end;

                    if TempMarketingTextAttributes.IsEmpty() then
                        Error(ItemWithNoAttributesErr);

                    if not OpenMarketingTextAttributePage(TempMarketingTextAttributes) then
                        exit;

                    Clear(Facts);
                    if ProductName <> '' then
                        Facts.Add(ProductNameTxt, ProductName);

                    if ItemCategory <> '' then
                        Facts.Add(ItemCategoryTxt, ItemCategory);

                    TempMarketingTextAttributes.SetRange(Selected, true);
                    if TempMarketingTextAttributes.FindSet() then begin
                        MaxFacts := 15;
                        repeat
                            Facts.Add(TempMarketingTextAttributes.Property, TempMarketingTextAttributes.Value);
                            FactCount += 1;
                        until (TempMarketingTextAttributes.Next() = 0) or (FactCount > MaxFacts);
                    end;

                    BuildAttributeString();
                    CurrPage.EntityTextPart.Page.SetFacts(Facts);

                    if not ValidateTextFormat(TextFormat) then
                        ValidateTextFormat(TextFormat::Tagline);
                end;
            }

            grid(AdvancedGrid)
            {
                group(AdvancedGroup)
                {
                    ShowCaption = false;
                    Visible = AdvancedOptionsVisible;

                    field(Emphasis; Emphasis)
                    {
                        Caption = 'Emphasize a quality';
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies an attribute to place emphasis on.';

                        trigger OnValidate()
                        begin
                            CurrPage.EntityTextPart.Page.SetTextEmphasis(Emphasis);
                        end;
                    }

                    field(Tone; Tone)
                    {
                        Caption = 'Tone of voice';
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the style of text to use in the generated text.';

                        trigger OnValidate()
                        begin
                            CurrPage.EntityTextPart.Page.SetTextTone(Tone);
                        end;
                    }
                }
            }

            field(TextFormat; TextFormat)
            {
                Caption = 'Format and length';
                ApplicationArea = Basic, Suite;
                ToolTip = 'Specifies the format of the generated text.';

                trigger OnValidate()
                begin
                    ValidateTextFormat(TextFormat);
                end;
            }

            group(EntityTextGroup)
            {
                ShowCaption = false;

                part(EntityTextPart; "Entity Text Part")
                {
                    ApplicationArea = Basic, Suite;
                    UpdatePropagation = Both;
                    Caption = 'Marketing text';
                }
            }
        }
    }

    trigger OnInit()
    var
        BaseAppModuleInfo: ModuleInfo;
        CallerModuleInfo: ModuleInfo;
    begin
        AdvancedOptionsVisible := false;
        CurrPage.EntityTextPart.Page.SetHasAdvancedOptions(true);
        CurrPage.EntityTextPart.Page.SetContentCaption(MarketingTextLbl);

        NavApp.GetCurrentModuleInfo(BaseAppModuleInfo);
        NavApp.GetCallerModuleInfo(CallerModuleInfo);

        if CallerModuleInfo.Id() <> BaseAppModuleInfo.Id() then
            Error(InvalidAppErr);
    end;

    trigger OnAfterGetCurrRecord()
    var
        Item: Record Item;
        EntityText: Codeunit "Entity Text";
        Handled: Boolean;
    begin
        AdvancedOptionsVisible := CurrPage.EntityTextPart.Page.ShowAdvancedOptions();

        if HasLoaded then
            exit;

        EntityText.OnRequestEntityContext(Rec."Source Table Id", Rec."Source System Id", Rec.Scenario, AllFacts, Tone, TextFormat, Handled);

        BuildInitialFacts();
        BuildAttributeString();

        Item.GetBySystemId(Rec."Source System Id");
        DescriptionValue := StrSubstNo(DescriptionTxt, CopilotTxt, Item.Description);

        CurrPage.EntityTextPart.Page.SetContext(EntityText.GetText(Rec), Facts, Tone, TextFormat);
        HasLoaded := true;
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if CloseAction <> Action::LookupOK then
            exit(true);

        CurrPage.EntityTextPart.Page.UpdateRecord(Rec);
        Rec.Modify();
    end;

    local procedure OpenMarketingTextAttributePage(var TempMarketingTextAttributes: Record "Marketing Text Attributes" temporary): Boolean
    var
        MarketingText: Codeunit "Marketing Text";
    begin
        TempMarketingTextAttributes.SetRange(Selected);
        Page.RunModal(Page::"Marketing Text Attributes", TempMarketingTextAttributes);

        TempMarketingTextAttributes.SetRange(Selected, true);
        if (MarketingText.GetItemRecordFactCount(AllFacts) < 2) and TempMarketingTextAttributes.IsEmpty() then
            if Confirm(MustSelectAttributeQst) then
                exit(OpenMarketingTextAttributePage(TempMarketingTextAttributes))
            else
                exit(false);

        exit(true);
    end;

    local procedure BuildInitialFacts()
    var
        FactKey: Text;
        FactCount: Integer;
        MaxFacts: Integer;
    begin
        CanSelectAttributes := AllFacts.Count() > 2; // more than two facts are required to customize attributes

        MaxFacts := 15;
        foreach FactKey in AllFacts.Keys() do begin
            if FactCount < MaxFacts then
                Facts.Add(FactKey, AllFacts.Get(FactKey))
            else
                exit;

            FactCount += 1;
        end;
    end;

    [TryFunction]
    local procedure ValidateTextFormat(NewFormat: Enum "Entity Text Format")
    var
        MarketingText: Codeunit "Marketing Text";
        MinFacts: Integer;
    begin
        MinFacts := 4;

        if (NewFormat <> NewFormat::Tagline) and (Facts.Count() < MinFacts) then
            if MarketingText.GetItemRecordFactCount(Facts) > 1 then
                Error(TwoAttributesRequiredToChangeFormatErr)
            else
                Error(ThreeAttributesRequiredToChangeFormatErr);

        TextFormat := NewFormat;
        CurrPage.EntityTextPart.Page.SetTextFormat(NewFormat);
    end;

    local procedure BuildAttributeString()
    var
        MarketingText: Codeunit "Marketing Text";
        Attribute: Text;
        FactValues: List of [Text];
        AttributeOffset: Integer;
    begin
        AttributeOffset := MarketingText.GetItemRecordFactCount(Facts);

        if Facts.Count() <= AttributeOffset then begin
            Attributes := AddAttributesSuggestionTxt;
            exit;
        end;

        Clear(Attributes);
        if Facts.ContainsKey(ItemCategoryTxt) then begin
            Facts.Get(ItemCategoryTxt, Attributes);
            Attributes += ': ';
        end;

        FactValues := Facts.Values();
        foreach Attribute in FactValues.GetRange(AttributeOffset + 1, FactValues.Count() - AttributeOffset) do
            Attributes += Attribute + ', ';

        Attributes := DelChr(Attributes, '>', ', ');
    end;

    var
        Tone: Enum "Entity Text Tone";
        TextFormat: Enum "Entity Text Format";
        Emphasis: Enum "Entity Text Emphasis";
        AdvancedOptionsVisible: Boolean;
        Attributes: Text;
        CanSelectAttributes: Boolean;
        DescriptionValue: Text;
        HasLoaded: Boolean;
        AllFacts: Dictionary of [Text, Text];
        Facts: Dictionary of [Text, Text];
        InvalidAppErr: Label 'The Edit Marketing Text page could not be opened as it cannot be opened from another extension.';
        DescriptionTxt: Label 'Choose how %1 suggests marketing text for ''%2'' (preview)', Comment = '%1 is Copilot, %2 is the item description.';
        MustSelectAttributeQst: Label 'At least one attribute must be included. Would you like to select one?';
        AddAttributesSuggestionTxt: Label 'Add item attributes to improve accuracy';
        ItemWithNoAttributesErr: Label 'This item does not have any item attributes.';
        ThreeAttributesRequiredToChangeFormatErr: Label 'Copilot uses information from the item attributes to suggest marketing text.\To use other formats, select at least three item attributes and try again.';
        TwoAttributesRequiredToChangeFormatErr: Label 'Copilot uses information from the item attributes to suggest marketing text.\To use other formats, select at least two item attributes and try again.';
        CopilotTxt: Label 'Copilot', Locked = true;
        ProductNameTxt: Label 'Product Name', Locked = true;
        ItemCategoryTxt: Label 'Item Category', Locked = true;
        MarketingTextLbl: Label 'Marketing Text';
}
#endif