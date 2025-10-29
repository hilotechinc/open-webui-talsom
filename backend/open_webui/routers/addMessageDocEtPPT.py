from fastapi import HTTPException, status


def validate_legacy_office_formats(file_extension: str):
    """
    Bloque les anciens formats Office (.doc et .ppt) avec des messages instructifs.

    Args:
        file_extension: L'extension du fichier (sans le point)

    Raises:
        HTTPException: Si le fichier est au format .doc ou .ppt
    """
    # Bloquer spécifiquement les fichiers .doc et .ppt avec un message instructif
    if file_extension.lower() == "doc":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Les fichiers .doc (ancien format Word) ne sont pas pris en charge. Veuillez convertir votre fichier en .docx (format Word moderne) : Ouvrez le fichier dans Word > Fichier > Enregistrer sous > Format .docx"
        )

    if file_extension.lower() == "ppt":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Les fichiers .ppt (ancien format PowerPoint) ne sont pas pris en charge. Veuillez convertir votre fichier en .pptx (format PowerPoint moderne) : Ouvrez le fichier dans PowerPoint > Fichier > Enregistrer sous > Format .pptx"
        )
