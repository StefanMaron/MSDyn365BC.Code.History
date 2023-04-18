codeunit 132225 "Library - Item Reference"
{
    // Unsupported version tags:
    // 
    // Contains all utility functions related to Item Reference.

    EventSubscriberInstance = Manual;

    trigger OnRun()
    begin
    end;

    var
        LibraryUtility: Codeunit "Library - Utility";
        LibraryItemReference: Codeunit "Library - Item Reference";

    procedure CreateItemReference(var ItemReference: Record "Item Reference"; ItemNo: Code[20]; ReferenceType: Enum "Item Reference Type"; ReferenceTypeNo: Code[20])
    begin
        CreateItemReferenceWithNo(
            ItemReference, LibraryUtility.GenerateRandomCode(ItemReference.FieldNo("Reference No."), DATABASE::"Item Reference"),
            ItemNo, ReferenceType, ReferenceTypeNo);
    end;

    procedure CreateItemReference(var ItemReference: Record "Item Reference"; ItemNo: Code[20]; VariantCode: Code[10]; UnitOfMeasureCode: Code[10]; ReferenceType: Enum "Item Reference Type"; ReferenceTypeNo: Code[20]; ReferenceNo: Code[50])
    begin
        ItemReference.Init();
        ItemReference.Validate("Item No.", ItemNo);
        ItemReference.Validate("Variant Code", VariantCode);
        ItemReference.Validate("Unit of Measure", UnitOfMeasureCode);
        ItemReference.Validate("Reference Type", ReferenceType);
        ItemReference.Validate("Reference Type No.", ReferenceTypeNo);
        ItemReference.Validate("Reference No.", ReferenceNo);
        ItemReference.Insert(true);
    end;

    [Scope('OnPrem')]
    procedure CreateItemReferenceWithNo(var ItemReference: Record "Item Reference"; ItemRefNo: Code[50]; ItemNo: Code[20]; ItemRefType: Enum "Item Reference Type"; ItemRefTypeNo: Code[20])
    begin
        ItemReference.Init();
        ItemReference.Validate("Item No.", ItemNo);
        ItemReference.Validate("Reference Type", ItemRefType);
        ItemReference.Validate("Reference Type No.", ItemRefTypeNo);
        ItemReference.Validate("Reference No.", ItemRefNo);
        ItemReference.Insert(true);
    end;

    procedure EnableFeature(Bind: Boolean)
    begin
        // turn on ItemReferenceMgt.IsEnable()
        UnbindSubscription(LibraryItemReference);
        if Bind then
            BindSubscription(LibraryItemReference);
    end;

    procedure DisableFeature()
    begin
        // turn off ItemReferenceMgt.IsEnable()
        UnbindSubscription(LibraryItemReference);
    end;
}
