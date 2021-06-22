page 5985 "Service Item Replacement"
{
    Caption = 'Service Item Replacement';
    PageType = StandardDialog;

    layout
    {
        area(content)
        {
            group(Control1)
            {
                ShowCaption = false;
                group("Old Service Item")
                {
                    Caption = 'Old Service Item';
                    field(ServItemNo; ServItemNo)
                    {
                        ApplicationArea = Service;
                        Caption = 'Service Item No.';
                        Editable = false;
                    }
                    field("Item.""No."""; Item."No.")
                    {
                        ApplicationArea = Service;
                        Caption = 'Item No.';
                        Editable = false;
                    }
                    field("Item.Description"; Item.Description)
                    {
                        ApplicationArea = Service;
                        Caption = 'Item Description';
                        Editable = false;
                    }
                    field(ServItemVariantCode; ServItemVariantCode)
                    {
                        ApplicationArea = Planning;
                        Caption = 'Variant Code';
                        Editable = false;
                    }
                    field(OldSerialNo; OldSerialNo)
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Serial No.';
                        Editable = false;
                    }
                }
                group("New Service Item")
                {
                    Caption = 'New Service Item';
                    field("Item No."; Item."No.")
                    {
                        ApplicationArea = Service;
                        Caption = 'Item No.';
                        Editable = false;
                    }
                    field("Item Description"; Item.Description)
                    {
                        ApplicationArea = Service;
                        Caption = 'Item Description';
                        Editable = false;
                    }
                    field(VariantCode; VariantCode)
                    {
                        ApplicationArea = Planning;
                        Caption = 'Variant Code';

                        trigger OnLookup(var Text: Text): Boolean
                        begin
                            ItemVariant.Reset();
                            ItemVariant.SetRange("Item No.", ItemNo);
                            if PAGE.RunModal(PAGE::"Item Variants", ItemVariant) = ACTION::LookupOK then
                                VariantCode := ItemVariant.Code;
                        end;

                        trigger OnValidate()
                        begin
                            if VariantCode <> '' then begin
                                ItemVariant.Reset();
                                ItemVariant.SetRange("Item No.", ItemNo);
                                ItemVariant.SetRange(Code, VariantCode);
                                if not ItemVariant.FindFirst then
                                    Error(
                                      Text000,
                                      ItemVariant.TableCaption, ItemNo, VariantCode);
                            end;
                        end;
                    }
                    field(NewSerialNo; NewSerialNo)
                    {
                        ApplicationArea = ItemTracking;
                        Caption = 'Serial No.';

                        trigger OnAssistEdit()
                        var
                            ItemLedgEntry: Record "Item Ledger Entry";
                        begin
                            Clear(ItemLedgEntry);
                            ItemLedgEntry.SetCurrentKey("Item No.", Open);
                            ItemLedgEntry.SetRange("Item No.", ItemNo);
                            ItemLedgEntry.SetRange(Open, true);
                            ItemLedgEntry.SetRange("Variant Code", VariantCode);
                            ItemLedgEntry.SetFilter("Serial No.", '<>%1', '');
                            if PAGE.RunModal(0, ItemLedgEntry) = ACTION::LookupOK then
                                NewSerialNo := ItemLedgEntry."Serial No.";
                        end;
                    }
                    field(CopyComponents; CopyComponentsFrom)
                    {
                        ApplicationArea = Service;
                        Caption = 'Copy Components From';
                        Enabled = CopyComponentsEnable;
                        OptionCaption = 'None,Item BOM,Old Service Item,Old Service Item w/o Serial No.';

                        trigger OnValidate()
                        begin
                            case CopyComponentsFrom of
                                CopyComponentsFrom::"Item BOM":
                                    if not Item."Assembly BOM" then
                                        Error(
                                          Text002,
                                          Item.FieldCaption("Assembly BOM"),
                                          Item.TableCaption,
                                          Item.FieldCaption("No."),
                                          Item."No.");
                                CopyComponentsFrom::"Old Service Item",
                              CopyComponentsFrom::"Old Service Item w/o Serial No.":
                                    if not ServItem."Service Item Components" then
                                        Error(
                                          Text002,
                                          ServItem.FieldCaption("Service Item Components"),
                                          ServItem.TableCaption,
                                          ServItem.FieldCaption("No."),
                                          ServItem."No.")
                            end;
                        end;
                    }
                }
                field(Replacement; Replacement)
                {
                    ApplicationArea = Service;
                    Caption = 'Replacement';
                    OptionCaption = 'Temporary,Permanent';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnInit()
    begin
        CopyComponentsEnable := true;
    end;

    trigger OnOpenPage()
    begin
        ServItem.Get(ServItemNo);
        OldSerialNo := ServItem."Serial No.";
        ServItemVariantCode := ServItem."Variant Code";
        if not Item.Get(ServItem."Item No.") then
            Clear(Item);

        ServItem.CalcFields("Service Item Components");
        Item.CalcFields("Assembly BOM");
        CopyComponentsEnable := ServItem."Service Item Components" or Item."Assembly BOM"
    end;

    var
        Text000: Label 'The %1 %2,%3 does not exists.', Comment = 'The Item Variant LS-10PC , LS-10PC-B does not exists.';
        Item: Record Item;
        ServItem: Record "Service Item";
        ItemVariant: Record "Item Variant";
        Replacement: Option "Temporary",Permanent;
        OldSerialNo: Code[50];
        NewSerialNo: Code[50];
        ServItemNo: Code[20];
        ItemNo: Code[20];
        VariantCode: Code[10];
        ServItemVariantCode: Code[10];
        CopyComponentsFrom: Option "None","Item BOM","Old Service Item","Old Service Item w/o Serial No.";
        Text002: Label 'There is no %1 in the %2 %3 %4.', Comment = 'There is no Assembly BOM in the Item No. 1002';
        [InDataSet]
        CopyComponentsEnable: Boolean;

    procedure SetValues(ServItemNo2: Code[20]; ItemNo2: Code[20]; VariantCode2: Code[10])
    begin
        ServItemNo := ServItemNo2;
        ItemNo := ItemNo2;
        VariantCode := VariantCode2;
    end;

    procedure ReturnSerialNo(): Text[50]
    begin
        exit(NewSerialNo);
    end;

    procedure ReturnReplacement(): Integer
    begin
        exit(Replacement);
    end;

    procedure ReturnVariantCode(): Text[10]
    begin
        exit(VariantCode);
    end;

    procedure ReturnCopyComponentsFrom(): Integer
    begin
        exit(CopyComponentsFrom);
    end;

    procedure SetParameters(VariantCodeFrom: Code[10]; NewSerialNoFrom: Code[20]; NewCopyComponentsFrom: Option; ReplacementFrom: Option)
    begin
        VariantCode := VariantCodeFrom;
        NewSerialNo := NewSerialNoFrom;
        CopyComponentsFrom := NewCopyComponentsFrom;
        Replacement := ReplacementFrom;
    end;
}

