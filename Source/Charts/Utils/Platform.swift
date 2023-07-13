import Foundation

/** This file provides a thin abstraction layer atop of UIKit (iOS, tvOS) and Cocoa (OS X). The two APIs are very much 
alike, and for the chart library's usage of the APIs it is often sufficient to typealias one to the other. The NSUI*
types are aliased to either their UI* implementation (on iOS) or their NS* implementation (on OS X). */
#if os(iOS) || os(tvOS)
	import UIKit


    public typealias ParagraphStyle = NSParagraphStyle
    public typealias MutableParagraphStyle = NSMutableParagraphStyle
    public typealias TextAlignment = NSTextAlignment
	public typealias NSUIFont = UIFont
	public typealias NSUIImage = UIImage
	public typealias NSUIScrollView = UIScrollView
    public typealias NSUIScreen = UIScreen
	public typealias NSUIDisplayLink = CADisplayLink

    extension NSUIColor
    {
        var nsuirgba: (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat)? {
            var red: CGFloat = 0
            var green: CGFloat = 0
            var blue: CGFloat = 0
            var alpha: CGFloat = 0

            guard getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
                return nil
            }

            return (red: red, green: green, blue: blue, alpha: alpha)
        }
    }

    open class NSUIView: UIView
    {
        @objc var nsuiLayer: CALayer?
        {
            return self.layer
        }
    }

    extension UIScrollView
    {
        @objc var nsuiIsScrollEnabled: Bool
        {
            get { return isScrollEnabled }
            set { isScrollEnabled = newValue }
        }
    }
    
    extension UIScreen
    {
        @objc final var nsuiScale: CGFloat
        {
            return self.scale
        }
    }

    func NSUIMainScreen() -> NSUIScreen?
    {
        return NSUIScreen.main
    }

#endif

#if os(OSX)
	import Cocoa
	import Quartz

    public typealias ParagraphStyle = NSParagraphStyle
    public typealias MutableParagraphStyle = NSMutableParagraphStyle
    public typealias TextAlignment = NSTextAlignment
    public typealias NSUIFont = NSFont
    public typealias NSUIImage = NSImage
    public typealias NSUIScrollView = NSScrollView
    public typealias NSUIScreen = NSScreen

	/** On OS X there is no CADisplayLink. Use a 60 fps timer to render the animations. */
	public class NSUIDisplayLink
    {
        private var timer: Timer?
        private var displayLink: CVDisplayLink?
        private var _timestamp: CFTimeInterval = 0.0
        
        private weak var _target: AnyObject?
        private var _selector: Selector
        
        public var timestamp: CFTimeInterval
        {
            return _timestamp
        }

		init(target: AnyObject, selector: Selector)
        {
            _target = target
            _selector = selector
            
            if CVDisplayLinkCreateWithActiveCGDisplays(&displayLink) == kCVReturnSuccess
            {
                
                CVDisplayLinkSetOutputCallback(displayLink!, { (displayLink, inNow, inOutputTime, flagsIn, flagsOut, userData) -> CVReturn in
                    
                    let _self = unsafeBitCast(userData, to: NSUIDisplayLink.self)
                    
                    _self._timestamp = CFAbsoluteTimeGetCurrent()
                    _self._target?.performSelector(onMainThread: _self._selector, with: _self, waitUntilDone: false)
                    
                    return kCVReturnSuccess
                    }, Unmanaged.passUnretained(self).toOpaque())
            }
            else
            {
                timer = Timer(timeInterval: 1.0 / 60.0, target: target, selector: selector, userInfo: nil, repeats: true)
            }
		}
        
        deinit
        {
            stop()
        }

        open func add(to runloop: RunLoop, forMode mode: RunLoop.Mode)
        {
            if displayLink != nil
            {
                CVDisplayLinkStart(displayLink!)
            }
            else if timer != nil
            {
                runloop.add(timer!, forMode: mode)
            }
		}

        open func remove(from: RunLoop, forMode: RunLoop.Mode)
        {
            stop()
		}
        
        private func stop()
        {
            if displayLink != nil
            {
                CVDisplayLinkStop(displayLink!)
            }
            if timer != nil
            {
                timer?.invalidate()
            }
        }
	}

    extension NSUIColor
    {
        var nsuirgba: (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat)? {
            var red: CGFloat = 0
            var green: CGFloat = 0
            var blue: CGFloat = 0
            var alpha: CGFloat = 0

            guard let colorSpaceModel = cgColor.colorSpace?.model else {
                return nil
            }
            guard colorSpaceModel == .rgb else {
                return nil
            }

            getRed(&red, green: &green, blue: &blue, alpha: &alpha)
            return (red: red, green: green, blue: blue, alpha: alpha)
        }
    }

	extension NSView
    {
		final var nsuiGestureRecognizers: [NSGestureRecognizer]?
        {
			return self.gestureRecognizers
		}
	}

    extension NSScrollView
    {
        var nsuiIsScrollEnabled: Bool
        {
            get { return scrollEnabled }
            set { scrollEnabled = newValue }
        }
    }
    
	open class NSUIView: NSView
    {
        /// A private constant to set the accessibility role during initialization.
        /// It ensures parity with the iOS element ordering as well as numbered counts of chart components.
        /// (See Platform+Accessibility for details)
        private let role: NSAccessibility.Role = .list

        public override init(frame frameRect: NSRect)
        {
            super.init(frame: frameRect)
            setAccessibilityRole(role)
        }

        required public init?(coder decoder: NSCoder)
        {
            super.init(coder: decoder)
            setAccessibilityRole(role)
        }

		public final override var isFlipped: Bool
        {
			return true
		}

		func setNeedsDisplay()
        {
			self.setNeedsDisplay(self.bounds)
		}

		open var backgroundColor: NSUIColor?
        {
            get
            {
                return self.layer?.backgroundColor == nil
                    ? nil
                    : NSColor(cgColor: self.layer!.backgroundColor!)
            }
            set
            {
                self.wantsLayer = true
                self.layer?.backgroundColor = newValue == nil ? nil : newValue!.cgColor
            }
        }

		final var nsuiLayer: CALayer?
        {
			return self.layer
		}
	}

	extension NSFont
    {
		var lineHeight: CGFloat
        {
			// Not sure if this is right, but it looks okay
			return self.boundingRectForFont.size.height
		}
	}

	extension NSScreen
    {
		final var nsuiScale: CGFloat
        {
			return self.backingScaleFactor
		}
	}

	extension NSImage
    {
		var cgImage: CGImage?
        {
            return self.cgImage(forProposedRect: nil, context: nil, hints: nil)
		}
	}

	extension NSScrollView
    {
		var scrollEnabled: Bool
        {
			get
            {
				return true
			}
            set
            {
                // FIXME: We can't disable  scrolling it on OSX
            }
		}
    }

    extension NSBezierPath
    {
        var cgPath: CGPath
        {
            let mutablePath = CGMutablePath()
            var points = [CGPoint](repeating: .zero, count: 3)
            for i in 0 ..< elementCount
            {
                let type = element(at: i, associatedPoints: &points)
                switch type
                {
                case .moveToBezierPathElement:
                    mutablePath.move(
                        to: CGPoint(
                            x: points[0].x,
                            y: points[0].y
                        )
                    )
                case .lineToBezierPathElement:
                    mutablePath.addLine(
                        to: CGPoint(
                            x: points[0].x,
                            y: points[0].y
                        )
                    )
                case .curveToBezierPathElement:
                    mutablePath.addCurve(
                        to: CGPoint(
                            x: points[2].x,
                            y: points[2].y
                        ),
                        control1: CGPoint(
                            x: points[0].x,
                            y: points[0].y
                        ),
                        control2: CGPoint(
                            x: points[1].x,
                            y: points[1].y
                        )
                    )
                case .closePathBezierPathElement:
                    mutablePath.closeSubpath()
                }
            }
            return mutablePath
        }
    }
    
    extension NSString
    {
        // iOS: size(attributes: ...), OSX: size(withAttributes: ...)
        // Both are translated into sizeWithAttributes: on ObjC. So conflict...
        @nonobjc
        func size(attributes attrs: [String : Any]? = nil) -> NSSize
        {
            return size(withAttributes: attrs)
        }
    }

	func NSUIGraphicsGetCurrentContext() -> CGContext?
    {
		return NSGraphicsContext.current()?.cgContext
	}

	func NSUIGraphicsPushContext(_ context: CGContext)
    {
        let cx = NSGraphicsContext(cgContext: context, flipped: true)
		NSGraphicsContext.saveGraphicsState()
		NSGraphicsContext.setCurrent(cx)
	}

	func NSUIGraphicsPopContext()
    {
		NSGraphicsContext.restoreGraphicsState()
	}

	func NSUIImagePNGRepresentation(_ image: NSUIImage) -> Data?
    {
		image.lockFocus()
		let rep = NSBitmapImageRep(focusedViewRect: NSMakeRect(0, 0, image.size.width, image.size.height))
		image.unlockFocus()
		return rep?.representation(using: NSPNGFileType, properties: [:])
	}

	func NSUIImageJPEGRepresentation(_ image: NSUIImage, _ quality: CGFloat = 0.9) -> Data?
    {
		image.lockFocus()
		let rep = NSBitmapImageRep(focusedViewRect: NSMakeRect(0, 0, image.size.width, image.size.height))
		image.unlockFocus()
        return rep?.representation(using: NSJPEGFileType, properties: [NSImageCompressionFactor: quality])
	}

	private var imageContextStack: [CGFloat] = []

	func NSUIGraphicsBeginImageContextWithOptions(_ size: CGSize, _ opaque: Bool, _ scale: CGFloat)
    {
		var scale = scale
		if scale == 0.0
        {
			scale = NSScreen.main()?.backingScaleFactor ?? 1.0
		}

		let width = Int(size.width * scale)
		let height = Int(size.height * scale)

		if width > 0 && height > 0
        {
			imageContextStack.append(scale)

			let colorSpace = CGColorSpaceCreateDeviceRGB()
            
			guard let ctx = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 4*width, space: colorSpace, bitmapInfo: (opaque ?  CGImageAlphaInfo.noneSkipFirst.rawValue : CGImageAlphaInfo.premultipliedFirst.rawValue))
                else { return }
            
			ctx.concatenate(CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: CGFloat(height)))
			ctx.scaleBy(x: scale, y: scale)
			NSUIGraphicsPushContext(ctx)
		}
	}

	func NSUIGraphicsGetImageFromCurrentImageContext() -> NSUIImage?
    {
		if !imageContextStack.isEmpty
        {
			guard let ctx = NSUIGraphicsGetCurrentContext()
                else { return nil }
            
			let scale = imageContextStack.last!
			if let theCGImage = ctx.makeImage()
            {
                let size = CGSize(width: CGFloat(ctx.width) / scale, height: CGFloat(ctx.height) / scale)
				let image = NSImage(cgImage: theCGImage, size: size)
				return image
			}
		}
		return nil
	}

	func NSUIGraphicsEndImageContext()
    {
		if imageContextStack.last != nil
        {
			imageContextStack.removeLast()
			NSUIGraphicsPopContext()
		}
	}

	func NSUIMainScreen() -> NSUIScreen?
    {
		return NSUIScreen.main
	}
    
#endif
