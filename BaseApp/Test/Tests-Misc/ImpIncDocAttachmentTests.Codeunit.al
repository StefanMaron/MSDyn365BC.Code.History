codeunit 134419 "Imp. Inc.Doc. Attachment Tests"
{
    Subtype = Test;
    TestPermissions = NonRestrictive;

    trigger OnRun()
    begin
        // [FEATURE] [Incoming Documents] [Attachment]
    end;

    var
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        Assert: Codeunit Assert;
        LibraryRandom: Codeunit "Library - Random";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        Initialized: Boolean;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Imp. Inc.Doc. Attachment Tests");
        LibrarySetupStorage.Restore();
        if Initialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Imp. Inc.Doc. Attachment Tests");

        Initialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Imp. Inc.Doc. Attachment Tests");
    end;


    [Test]
    procedure ImportPurchAttachmentTest()
    var
        PurchaseHeader: Record "Purchase Header";
        IncomingDocumentAttachment: Record "Incoming Document Attachment";
        ImportAttachmentIncDoc: Codeunit "Import Attachment - Inc. Doc.";
        TempBlob: Codeunit "Temp Blob";
        FileName: Text[250];
        FileOutStream: OutStream;
        FileNameTxt: Label 'dummy.txt', Locked = true;
        DummyText: Text;
    begin
        // [SCENARIO] Attach a new file to a Purch. Document
        Initialize();

        // [GIVEN] Purchase Order
        LibraryPurchase.CreatePurchaseOrder(PurchaseHeader);

        // [GIVEN] Dummy Document to Attach
        TempBlob.CreateOutStream(FileOutStream);
        DummyText := LibraryRandom.RandText(100);
        FileOutStream.WriteText(DummyText);
        FileName := FileNameTxt;

        // [WHEN] When New Attachment for Purchase Document is created.
        IncomingDocumentAttachment.NewAttachmentFromPurchaseDocument(PurchaseHeader, FileName, TempBlob);

        // [THEN] Attachment is identical to Dummy Document and Purchase Header is updated with Incoming Document Entry No.
        VerifyIncomingDocumentAttachment(IncomingDocumentAttachment, DummyText, FileName);
        PurchaseHeader.Find('=');
        Assert.AreEqual(IncomingDocumentAttachment."Incoming Document Entry No.", PurchaseHeader."Incoming Document Entry No.", 'Incoming Document Entry No. should be updated in the document.');
    end;

    local procedure VerifyIncomingDocumentAttachment(IncomingDocumentAttachment: Record "Incoming Document Attachment"; TextToTest: Text; FileName: Text[250])
    var
        TempBlob: Codeunit "Temp Blob";
        FileInStream: InStream;
        FileManagement: Codeunit "File Management";
        Name: Text;
        ActualFileContent: Text;
    begin
        Name := FileManagement.GetFileNameWithoutExtension(FileName);
        Assert.AreEqual(Name, IncomingDocumentAttachment.Name, 'Name of the Incoming Document Attachment should be the FileName without extension.');

        TempBlob.FromRecord(IncomingDocumentAttachment, IncomingDocumentAttachment.FieldNo(Content));
        TempBlob.CreateInStream(FileInStream);
        FileInStream.ReadText(ActualFileContent);
        Assert.AreEqual(TextToTest, ActualFileContent, 'File Content should be identical');
    end;

}
