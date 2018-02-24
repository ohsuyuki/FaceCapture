//
//  UploadViewController.swift
//  FaceCapture
//
//  Created by osu on 2018/02/24.
//  Copyright © 2018 osu. All rights reserved.
//

import UIKit

class UploadViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    var faceCaptureController: FaceCaptureController? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell{
        let cell:UICollectionViewCell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)

        guard let faceCaptureController = self.faceCaptureController,
            indexPath.row < faceCaptureController.capturedFaceSets.count,
            let faceCaptureSet = faceCaptureController.capturedFaceSets[indexPath.row] else {
            return cell
        }

        let imageView = cell.contentView.viewWithTag(1) as! UIImageView
        imageView.image = faceCaptureSet.image
        
        let label = cell.contentView.viewWithTag(2) as! UILabel
        label.text = String(describing: FaceCaptureDirection(rawValue: indexPath.row)!)
        
        return cell
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let faceCaptureController = self.faceCaptureController else {
            return 0
        }

        return faceCaptureController.capturedFaceSets.count
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cellSize:CGFloat = view.bounds.width/2 - 2
        return CGSize(width: cellSize, height: cellSize)
    }

}
