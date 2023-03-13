import 'package:camerawesome/src/photofilters/filters/subfilters.dart';

import 'package:camerawesome/src/photofilters/utils/convolution_kernels.dart';
import 'package:camerawesome/src/photofilters/filters/image_filters.dart';

final presetConvolutionFiltersList = [
  ImageFilter(name: "Identity")
    ..addSubFilter(ConvolutionSubFilter.fromKernel(identityKernel)),
  ImageFilter(name: "Sharpen")
    ..addSubFilter(ConvolutionSubFilter.fromKernel(sharpenKernel)),
  ImageFilter(name: "Emboss")
    ..addSubFilter(ConvolutionSubFilter.fromKernel(embossKernel)),
  ImageFilter(name: "Colored Edge Detection")
    ..subFilters
        .add(ConvolutionSubFilter.fromKernel(coloredEdgeDetectionKernel)),
  ImageFilter(name: "Edge Detection Medium")
    ..subFilters
        .add(ConvolutionSubFilter.fromKernel(edgeDetectionMediumKernel)),
  ImageFilter(name: "Edge Detection Hard")
    ..addSubFilter(ConvolutionSubFilter.fromKernel(edgeDetectionHardKernel)),
  ImageFilter(name: "Blur")
    ..addSubFilter(ConvolutionSubFilter.fromKernel(blurKernel)),
  ImageFilter(name: "Guassian 3x3")
    ..addSubFilter(ConvolutionSubFilter.fromKernel(guassian3x3Kernel)),
  ImageFilter(name: "Guassian 5x5")
    ..addSubFilter(ConvolutionSubFilter.fromKernel(guassian5x5Kernel)),
  ImageFilter(name: "Guassian 7x7")
    ..addSubFilter(ConvolutionSubFilter.fromKernel(guassian7x7Kernel)),
  ImageFilter(name: "Mean 3x3")
    ..addSubFilter(ConvolutionSubFilter.fromKernel(mean3x3Kernel)),
  ImageFilter(name: "Mean 5x5")
    ..addSubFilter(ConvolutionSubFilter.fromKernel(mean5x5Kernel)),
  ImageFilter(name: "Low Pass 3x3")
    ..addSubFilter(ConvolutionSubFilter.fromKernel(lowPass3x3Kernel)),
  ImageFilter(name: "Low Pass 5x5")
    ..addSubFilter(ConvolutionSubFilter.fromKernel(lowPass5x5Kernel)),
  ImageFilter(name: "High Pass 3x3")
    ..addSubFilter(ConvolutionSubFilter.fromKernel(highPass3x3Kernel)),
];
