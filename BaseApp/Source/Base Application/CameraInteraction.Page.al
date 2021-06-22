page 1910 "Camera Interaction"
{
    Caption = 'Camera Interaction';
    Editable = false;
    LinksAllowed = false;
    PageType = Card;
    ObsoleteState = Pending;
    ObsoleteReason = 'Replaced woth page 1908 Camera';
    ObsoleteTag = '15.3';

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
        CameraAvailable := Camera.IsAvailable();

        if not CameraAvailable then
            exit;

        if UseMediaUpload then begin
            Clear(MediaUpload);
            MediaUpload.RunModal();
        end else begin
            Clear(Camera);
            Camera.RunModal();
        end;
    end;

    var
        Camera: Page Camera;
        MediaUpload: Page "Media Upload";
        UseMediaUpload: Boolean;
        [InDataSet]
        CameraAvailable: Boolean;
        RequestedIgnoreError: Boolean;
        UnsupportedEncodingErr: Label 'Unsupported image encoding format: %1', Comment = '%1 = format';
        UnsupportedMediaErr: Label 'Unsupported media type: %1', Comment = '%1 = media type';
        UnsupportedSourceErr: Label 'Unsupported source type: %1', Comment = '%1 = source type';

    procedure AllowEdit(AllowEdit: Boolean)
    begin
        Camera.SetAllowEdit(AllowEdit);
    end;

    procedure GetPictureName(): Text
    begin
        exit('Picture');
    end;

    [TryFunction]
    local procedure TryGetPicture(Stream: InStream)
    begin
        if UseMediaUpload then
            MediaUpload.GetMedia(Stream)
        else
            Camera.GetPicture(Stream);
    end;

    procedure GetPicture(Stream: InStream): Boolean
    begin
        if not RequestedIgnoreError then
            TryGetPicture(Stream);
        // else ignore error
        if TryGetPicture(Stream) then;
    end;

    procedure EncodingType(EncodingType: Text)
    begin
        case EncodingType of
            'JPEG':
                Camera.SetEncodingType(Enum::"Image Encoding"::JPEG);
            'PNG':
                Camera.SetEncodingType(Enum::"Image Encoding"::PNG);
            else
                if not RequestedIgnoreError then
                    Error(UnsupportedEncodingErr);
        end;
    end;

    procedure MediaType(MediaType: Text)
    begin
        case MediaType of
            'AllMedia':
                MediaUpload.SetMediaType(Enum::"Media Type"::"All Media");
            'Picture':
                MediaUpload.SetMediaType(Enum::"Media Type"::Picture);
            'Video':
                MediaUpload.SetMediaType(Enum::"Media Type"::Video);
            else
                if not RequestedIgnoreError then
                    Error(UnsupportedMediaErr);
        end;
    end;

    procedure SourceType(SourceType: Text)
    begin
        case SourceType of
            'SavedPhotoAlbum':
                begin
                    UseMediaUpload := true;
                    MediaUpload.SetUploadFromSavedPhotoAlbum(true);
                end;
            'PhotoLibrary':
                begin
                    UseMediaUpload := true;
                    MediaUpload.SetUploadFromSavedPhotoAlbum(false);
                end;
            'Camera':
                UseMediaUpload := false;
            else
                if not RequestedIgnoreError then
                    Error(UnsupportedSourceErr);
        end;
    end;

    procedure IgnoreError(IgnoreError: Boolean)
    begin
        RequestedIgnoreError := IgnoreError;
    end;

    procedure Quality(Quality: Integer)
    begin
        Camera.SetQuality(Quality);
    end;
}

