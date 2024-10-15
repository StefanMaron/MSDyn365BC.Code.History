namespace Microsoft.Inventory.Tracking;

using Microsoft.Inventory.Item;

page 6513 "Enter Quantity to Create"
{
    Caption = 'Enter Quantity to Create';
    PageType = StandardDialog;
    SaveValues = true;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(ItemNo; ItemNo)
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Item No.';
                    ToolTip = 'Specifies the number of the item for which you want to assign serial numbers.';
                    Editable = false;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        Item."No." := ItemNo;
                        Page.RunModal(0, Item);
                    end;
                }
                field(VariantCode; VariantCode)
                {
                    ApplicationArea = Planning;
                    Caption = 'Variant Code';
                    ToolTip = 'Specifies the variant code of the item for which you want to assign serial numbers.';
                    Editable = false;

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        ItemVariant.Reset();
                        ItemVariant.SetRange("Item No.", ItemNo);
                        ItemVariant."Item No." := ItemNo;
                        ItemVariant.Code := VariantCode;
                        Page.RunModal(0, ItemVariant);
                    end;
                }
                field(QtyToCreate; QtyToCreate)
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Quantity to Create';
                    ToolTip = 'Specifies the total number of serial numbers to assign.';
                }
                field(CreateNewLotNo; CreateNewLotNo)
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Create New Lot No.';
                    ToolTip = 'Specifies whether to generate a new lot number and assign it to each serial number.';
                }
                field(CreateNewPackageNo; CreateNewPackageNo)
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Create New Package No.';
                    ToolTip = 'Specifies whether to generate a new package number and assign it to each serial number.';
                }
                field(CreateSNInfo; CreateSNInfo)
                {
                    ApplicationArea = ItemTracking;
                    Caption = 'Create SN Information';
                    ToolTip = 'Specifies whether to create a Serial Number Information card for each serial number.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        ItemNo := InitItemNo;
        VariantCode := InitVariantCode;
        QtyToCreate := InitQtyToCreate;
        CreateNewLotNo := InitCreateNewLotNo;
        CreateNewPackageNo := InitCreateNewPackageNo;
        CreateSNInfo := InitCreateSNInfo;
    end;

    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ItemNo: Code[20];
        VariantCode: Code[10];
        QtyToCreate: Integer;
        CreateNewLotNo: Boolean;
        CreateNewPackageNo: Boolean;
        CreateSNInfo: Boolean;
        InitItemNo: Code[20];
        InitVariantCode: Code[10];
        InitQtyToCreate: Integer;
        InitCreateNewLotNo: Boolean;
        InitCreateNewPackageNo: Boolean;
        InitCreateSNInfo: Boolean;

#if not CLEAN24
    [Obsolete('Replaced by namesake procedure with additional parameter SetCreateNewPackageNo.', '24.0')]
    procedure SetFields(SetItemNo: Code[20]; SetVariantCode: Code[10]; SetQtyToCreate: Integer; SetCreateNewLotNo: Boolean; SetCreateSNInfo: Boolean)
    begin
        SetFields(SetItemNo, SetVariantCode, SetQtyToCreate, SetCreateNewLotNo, false, SetCreateSNInfo);
    end;

    [Obsolete('Replaced by namesake procedure with additional parameter GetCreateNewPackageNo.', '24.0')]
    procedure GetFields(var GetQtyToCreate: Integer; var GetCreateNewLotNo: Boolean; var GetCreateSNInfo: Boolean)
    var
        DummyGetCreateNewPackageNo: Boolean;
    begin
        GetFields(GetQtyToCreate, GetCreateNewLotNo, DummyGetCreateNewPackageNo, GetCreateSNInfo);
    end;
#endif

    procedure SetFields(SetItemNo: Code[20]; SetVariantCode: Code[10]; SetQtyToCreate: Integer; SetCreateNewLotNo: Boolean; SetCreateNewPackageNo: Boolean; SetCreateSNInfo: Boolean)
    begin
        InitItemNo := SetItemNo;
        InitVariantCode := SetVariantCode;
        InitQtyToCreate := SetQtyToCreate;
        InitCreateNewLotNo := SetCreateNewLotNo;
        InitCreateNewPackageNo := SetCreateNewPackageNo;
        InitCreateSNInfo := SetCreateSNInfo;
    end;

    procedure GetFields(var GetQtyToCreate: Integer; var GetCreateNewLotNo: Boolean; var GetCreateNewPackageNo: Boolean; var GetCreateSNInfo: Boolean)
    begin
        GetQtyToCreate := QtyToCreate;
        GetCreateNewLotNo := CreateNewLotNo;
        GetCreateNewPackageNo := CreateNewPackageNo;
        GetCreateSNInfo := CreateSNInfo;
    end;
}

