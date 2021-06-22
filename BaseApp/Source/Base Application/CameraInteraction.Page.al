page 1910 "Camera Interaction"
{
    Caption = 'Camera Interaction';
    Editable = false;
    LinksAllowed = false;
    PageType = Card;

    layout
    {
        area(content)
        {
            group(TakingPicture)
            {
                Caption = 'Taking picture...';
                InstructionalText = 'Please take the picture using your camera.';
                Visible = CameraAvailable;
            }
            group(CameraNotSupported)
            {
                Caption = 'Could not connect to camera';
                InstructionalText = 'The camera on the device could not be accessed. Please make sure you are using a Dynamics Tenerife app for Windows, Android or iOS.';
                Visible = NOT CameraAvailable;
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        CameraAvailable := CameraProvider.IsAvailable;

        if not CameraAvailable then
            exit;

        CameraOptions := CameraOptions.CameraOptions;
        CameraOptions.Quality := RequestedQuality;
        CameraOptions.AllowEdit := RequestedAllowEdit;
        CameraOptions.EncodingType := RequestedEncodingType;
        CameraOptions.MediaType := RequestedMediaType;
        CameraOptions.SourceType := RequestedSourceType;

        CameraProvider := CameraProvider.Create;
        CameraProvider.RequestPictureAsync(CameraOptions);
    end;

    var
        TempBlob: Codeunit "Temp Blob";
        [RunOnClient]
        [WithEvents]
        CameraProvider: DotNet CameraProvider;
        CameraOptions: DotNet CameraOptions;
        [InDataSet]
        CameraAvailable: Boolean;
        RequestedAllowEdit: Boolean;
        SavedPictureName: Text;
        SavedPictureFilePath: Text;
        RequestedEncodingType: Text;
        RequestedMediaType: Text;
        RequestedSourceType: Text;
        PictureNotAvailableErr: Label 'The picture is not available.';
        RequestedIgnoreError: Boolean;
        RequestedQuality: Integer;

    procedure AllowEdit(AllowEdit: Boolean)
    begin
        RequestedAllowEdit := AllowEdit;
    end;

    procedure GetPictureName(): Text
    begin
        exit(SavedPictureName);
    end;

    procedure GetPicture(Stream: InStream): Boolean
    var
        FileManagement: Codeunit "File Management";
    begin
        if SavedPictureFilePath = '' then begin
            if not RequestedIgnoreError then
                Error(PictureNotAvailableErr);

            exit(false);
        end;

        FileManagement.BLOBImport(TempBlob, SavedPictureFilePath);
        TempBlob.CreateInStream(Stream);

        exit(true);
    end;

    procedure EncodingType(EncodingType: Text)
    begin
        RequestedEncodingType := EncodingType;
    end;

    procedure MediaType(MediaType: Text)
    begin
        RequestedMediaType := MediaType;
    end;

    procedure SourceType(SourceType: Text)
    begin
        RequestedSourceType := SourceType;
    end;

    procedure IgnoreError(IgnoreError: Boolean)
    begin
        RequestedIgnoreError := IgnoreError;
    end;

    procedure Quality(Quality: Integer)
    begin
        RequestedQuality := Quality;
    end;

    trigger CameraProvider::PictureAvailable(PictureName: Text; PictureFilePath: Text)
    begin
        SavedPictureFilePath := PictureFilePath;
        SavedPictureName := PictureName;

        CurrPage.Close;
    end;
}

