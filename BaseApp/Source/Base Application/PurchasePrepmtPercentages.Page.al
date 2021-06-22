page 665 "Purchase Prepmt. Percentages"
{
    Caption = 'Purchase Prepmt. Percentages';
    DataCaptionExpression = Caption;
    DelayedInsert = true;
    PageType = Worksheet;
    SourceTable = "Purchase Prepayment %";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(VendNoFilter; VendNoFilter)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Vendor No. Filter';
                    ToolTip = 'Specifies a filter for which purchase prepayment percentages display.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        VendList: Page "Vendor List";
                    begin
                        VendList.LookupMode := true;
                        if VendList.RunModal <> ACTION::LookupOK then
                            exit(false);
                        Text := VendList.GetSelectionFilter;
                        exit(true);
                    end;

                    trigger OnValidate()
                    begin
                        VendNoFilterOnAfterValidate;
                    end;
                }
                field(CodeFilterCtrl; ItemNoFilter)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Item No. Filter';
                    ToolTip = 'Specifies a filter which applies.';

                    trigger OnLookup(var Text: Text): Boolean
                    var
                        ItemList: Page "Item List";
                    begin
                        ItemList.LookupMode := true;
                        if ItemList.RunModal = ACTION::LookupOK then begin
                            Text := ItemList.GetSelectionFilter;
                            exit(true);
                        end;
                    end;

                    trigger OnValidate()
                    begin
                        ItemNoFilterOnAfterValidate;
                    end;
                }
                field(StartingDateFilter; StartingDateFilter)
                {
                    ApplicationArea = Prepayments;
                    Caption = 'Starting Date Filter';
                    ToolTip = 'Specifies a starting date filter for which purchase prepayment percentages will display.';

                    trigger OnValidate()
                    var
                        FilterTokens: Codeunit "Filter Tokens";
                    begin
                        FilterTokens.MakeDateFilter(StartingDateFilter);
                        StartingDateFilterOnAfterValid;
                    end;
                }
            }
            repeater(Control1)
            {
                ShowCaption = false;
                field("Vendor No."; "Vendor No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the vendor that the prepayment percentage for this item is valid for.';
                }
                field("Item No."; "Item No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the item for which the prepayment percentage is valid.';
                }
                field("Starting Date"; "Starting Date")
                {
                    ApplicationArea = Prepayments;
                    ToolTip = 'Specifies the date from which the purchase prepayment percentage is valid.';
                }
                field("Ending Date"; "Ending Date")
                {
                    ApplicationArea = Prepayments;
                    ToolTip = 'Specifies the date to which the purchase prepayment percentage is valid.';
                }
                field("Prepayment %"; "Prepayment %")
                {
                    ApplicationArea = Prepayments;
                    ToolTip = 'Specifies the prepayment percentage to use to calculate the prepayment for purchases.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetCurrRecord()
    begin
        SetEditable;
    end;

    trigger OnOpenPage()
    begin
        GetRecFilters;
        SetRecFilters;
    end;

    var
        VendNoFilter: Text;
        ItemNoFilter: Text;
        StartingDateFilter: Text[30];

    local procedure SetEditable()
    begin
    end;

    local procedure GetRecFilters()
    begin
        if HasFilter then begin
            VendNoFilter := GetFilter("Vendor No.");
            ItemNoFilter := GetFilter("Item No.");
            Evaluate(StartingDateFilter, GetFilter("Starting Date"));
        end;
    end;

    procedure SetRecFilters()
    begin
        if VendNoFilter <> '' then
            SetFilter("Vendor No.", VendNoFilter)
        else
            SetRange("Vendor No.");

        if StartingDateFilter <> '' then
            SetFilter("Starting Date", StartingDateFilter)
        else
            SetRange("Starting Date");

        if ItemNoFilter <> '' then
            SetFilter("Item No.", ItemNoFilter)
        else
            SetRange("Item No.");

        CurrPage.Update(false);
    end;

    procedure Caption(): Text
    var
        Item: Record Item;
        Vend: Record Vendor;
        ItemNoCaption: Text;
        PurchaseCodeCaption: Text;
    begin
        if ItemNoFilter <> '' then begin
            ItemNoCaption := StrSubstNo('%1 %2', Item.TableCaption, ItemNoFilter);
            if Item.Get(CopyStr(ItemNoFilter, 1, MaxStrLen(Item."No."))) then
                ItemNoCaption := ItemNoCaption + ' - ' + Item.Description;
        end;

        PurchaseCodeCaption := StrSubstNo('%1 %2', Vend.TableCaption, VendNoFilter);
        if Vend.Get(CopyStr(VendNoFilter, 1, MaxStrLen(Vend."No."))) then
            PurchaseCodeCaption := PurchaseCodeCaption + ' - ' + Vend.Name;

        exit(DelChr(ItemNoCaption + ' ' + PurchaseCodeCaption, '<>'))
    end;

    local procedure VendNoFilterOnAfterValidate()
    begin
        CurrPage.SaveRecord;
        SetRecFilters;
    end;

    local procedure StartingDateFilterOnAfterValid()
    begin
        CurrPage.SaveRecord;
        SetRecFilters;
    end;

    local procedure ItemNoFilterOnAfterValidate()
    begin
        CurrPage.SaveRecord;
        SetRecFilters;
    end;
}

